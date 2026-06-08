const path = require('path');
require('dotenv').config();
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const express = require('express');
const cron = require('node-cron');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

const JWT_SECRET = process.env.JWT_SECRET;

// Bezpiecznik: serwer nie powinien wstać bez skonfigurowanego sekretu JWT.
if (!JWT_SECRET) {
    throw new Error('Brak zmiennej JWT_SECRET. Skonfiguruj plik .env na podstawie .env.example.');
}

app.use(cors());
app.use(express.json());

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'Brak tokena, dostęp zabroniony.' });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Token nieprawidłowy lub wygasł.' });
        req.user = user;
        next();
    });
};

// POBIERANIE WSZYSTKICH LEKÓW UŻYTKOWNIKA (GET /api/medications)
app.get('/api/medications', authenticateToken, (req, res) => {
    const sql = 'SELECT * FROM medications WHERE userId = ?';
    db.all(sql, [req.user.userId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// DODAWANIE NOWEGO LEKU (POST /api/medications)
app.post('/api/medications', authenticateToken, (req, res) => {
    const { name, dosage, time, days } = req.body;

    // Walidacja: nazwa, dawka, godzina i dni są wymagane.
    if (!name || !name.trim() || !dosage || !time || !days) {
        return res.status(400).json({ error: 'Pola name, dosage, time i days są wymagane.' });
    }

    const sql = 'INSERT INTO medications (userId, name, dosage, time, days) VALUES (?, ?, ?, ?, ?)';

    db.run(sql, [req.user.userId, name, dosage, time, days], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID, message: 'Lek dodany pomyślnie!' });
    });
});

// EDYCJA LEKU (PUT /api/medications/:id)
app.put('/api/medications/:id', authenticateToken, (req, res) => {
    const { name, dosage, time, days } = req.body;
    const sql = 'UPDATE medications SET name = ?, dosage = ?, time = ?, days = ? WHERE id = ? AND userId = ?';

    db.run(sql, [name, dosage, time, days, req.params.id, req.user.userId], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: 'Nie znaleziono leku lub brak uprawnień.' });
        res.json({ message: 'Lek zaktualizowany.' });
    });
});

// USUWANIE LEKU (Bez usuwania historii - historia zostaje dla statystyk!)
app.delete('/api/medications/:id', authenticateToken, (req, res) => {
    const medId = req.params.id;
    const userId = req.user.userId;

    const sql = 'DELETE FROM medications WHERE id = ? AND userId = ?';
    db.run(sql, [medId, userId], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: 'Nie znaleziono leku lub brak uprawnień.' });
        res.json({ message: 'Lek został usunięty (dane historyczne zostały zachowane).' });
    });
});

// REJESTRACJA (POST /api/register)
app.post('/api/register', async (req, res) => {
    const { email, password, name } = req.body;

    if (!email || !password || !name) {
            return res.status(400).json({ error: 'Email, hasło i imię są wymagane!' });
    }

    try {
        // Hashowanie hasła o sile 10
        const hashedPassword = await bcrypt.hash(password, 10);

        // Zapis do bazy
        const sql = 'INSERT INTO users (email, password, name) VALUES (?, ?, ?)';
        db.run(sql, [email, hashedPassword, name], function(err) {
            if (err) {
                if (err.message.includes('UNIQUE')) {
                    return res.status(409).json({ error: 'Użytkownik o tym emailu już istnieje.' });
                }
                return res.status(500).json({ error: 'Błąd bazy danych.' });
            }
            res.status(201).json({ message: 'Rejestracja zakończona sukcesem!', userId: this.lastID });
        });
    } catch (error) {
        res.status(500).json({ error: 'Wystąpił błąd serwera.' });
    }
});

// LOGOWANIE (POST /api/login)
app.post('/api/login', (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email i hasło są wymagane!' });
    }

    // Wyszukiwanie użytkownika w bazie
    const sql = 'SELECT * FROM users WHERE email = ?';
    db.get(sql, [email], async (err, user) => {
        if (err) return res.status(500).json({ error: 'Błąd bazy danych.' });

        if (!user) {
            return res.status(401).json({ error: 'Nieprawidłowy email lub hasło.' });
        }

        // Porównanie hasła do tego w bazie
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ error: 'Nieprawidłowy email lub hasło.' });
        }

        // Generowanie tokentu JWT na 24h
        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '24h' });

        res.json({ message: 'Zalogowano pomyślnie!', token });
    });
});

// PROFIL (GET /api/user/me)
app.get('/api/user/me', authenticateToken, (req, res) => {
    const sql = 'SELECT id, email, name FROM users WHERE id = ?';
    db.get(sql, [req.user.userId], (err, user) => {
        if (err) return res.status(500).json({ error: 'Błąd bazy danych.' });
        if (!user) return res.status(404).json({ error: 'Użytkownik nie istnieje.' });

        res.json(user);
    });
});

app.get('/privacy', (req, res) => {
    res.sendFile(path.join(__dirname, 'privacy.html'));
});

// POBIERANIE HISTORII (GET /api/history)
app.get('/api/history', authenticateToken, (req, res) => {
    // Pobieramy historię i sortujemy od najnowszych wpisów (DESC)
    const sql = 'SELECT * FROM medication_history WHERE userId = ? ORDER BY takenAt DESC';
    db.all(sql, [req.user.userId], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// DODAWANIE WPISU DO HISTORII (POST /api/history)
app.post('/api/history', authenticateToken, (req, res) => {
    const { medicationId, medicationName, takenAt, status } = req.body;

    // Walidacja – upewniamy się, że status to TAKEN lub MISSED
    if (!status || !['TAKEN', 'MISSED'].includes(status.toUpperCase())) {
        return res.status(400).json({ error: "Status jest wymagany i musi wynosić 'TAKEN' lub 'MISSED'." });
    }

    const time = takenAt || new Date().toISOString();
    const sql = 'INSERT INTO medication_history (userId, medicationId, medicationName, takenAt, status) VALUES (?, ?, ?, ?, ?)';

    db.run(sql, [req.user.userId, medicationId, medicationName, time, status.toUpperCase()], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID, message: 'Wpis dodany do historii!' });
    });
});

// USUWANIE WPISU Z HISTORII (Cofanie akcji)
app.delete('/api/history/:id', authenticateToken, (req, res) => {
    const sql = 'DELETE FROM medication_history WHERE id = ? AND userId = ?';
    db.run(sql, [req.params.id, req.user.userId], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: 'Nie znaleziono wpisu w historii.' });
        res.json({ message: 'Cofnięto wpis w historii.' });
    });
});

// STATYSTYKI HISTORII (GET /api/history/stats)
app.get('/api/history/stats', authenticateToken, (req, res) => {
    const sql = `
        SELECT
            SUM(CASE WHEN status = 'TAKEN' THEN 1 ELSE 0 END) as taken,
            SUM(CASE WHEN status = 'MISSED' THEN 1 ELSE 0 END) as missed
        FROM medication_history
        WHERE userId = ?
    `;

    db.get(sql, [req.user.userId], (err, row) => {
        if (err) return res.status(500).json({ error: err.message });

        const taken = row.taken || 0;
        const missed = row.missed || 0;
        const total = taken + missed;

        // Liczymy skuteczność (jeśli brak wpisów, domyślnie dajemy 100%)
        const effectiveness = total > 0 ? Math.round((taken / total) * 100) : 100;

        // Zwracamy piękny, gotowy obiekt pod widok we Flutterze
        res.json({
            taken: taken,
            missed: missed,
            effectiveness: `${effectiveness}%`
        });
    });
});

if (require.main === module) {
    // ==========================================
    // CRON JOB: Automatyczne oznaczanie pominiętych leków o 23:59
    // ==========================================
    cron.schedule('59 23 * * *', () => {
        console.log('CRON: Rozpoczynam weryfikację pominiętych leków na koniec dnia...');

        // Ustawiamy dzisiejszy dzień i datę
        const jsDaysMap = ['Nd', 'Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb']; // 0 to Niedziela w JS
        const today = new Date();
        const todayStr = jsDaysMap[today.getDay()];
        const todayDateStr = today.toISOString().substring(0, 10); // Format YYYY-MM-DD

        // 1. Pobieramy wszystkie zaplanowane leki wszystkich użytkowników
        db.all('SELECT * FROM medications', [], (err, meds) => {
            if (err) return console.error('CRON błąd bazy:', err);

            meds.forEach(med => {
                // Jeśli lek jest przypisany na dzisiejszy dzień tygodnia
                if (med.days && med.days.includes(todayStr)) {

                    // 2. Sprawdzamy czy użytkownik ma wpis w historii na dzisiaj
                    const sqlCheck = 'SELECT id FROM medication_history WHERE medicationId = ? AND takenAt LIKE ?';
                    db.get(sqlCheck, [med.id, `${todayDateStr}%`], (err, row) => {

                        // 3. Brak jakiegokolwiek wpisu? Zapisujemy automatyczne MISSED
                        if (!row && !err) {
                            const sqlInsert = 'INSERT INTO medication_history (userId, medicationId, medicationName, takenAt, status) VALUES (?, ?, ?, ?, ?)';
                            // Podajemy czas 23:59 dla pewności
                            const missedTime = `${todayDateStr}T23:59:00.000Z`;

                            db.run(sqlInsert, [med.userId, med.id, med.name, missedTime, 'MISSED']);
                            console.log(`CRON: Oznaczono jako MISSED lek ${med.name} dla usera ${med.userId}`);
                        }
                    });
                }
            });
        });
    });

    app.listen(PORT, () => {
        console.log(`Serwer PILL4U działa na porcie http://localhost:${PORT}`);
    });
}

module.exports = app;