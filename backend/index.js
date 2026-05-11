require('dotenv').config();
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

const JWT_SECRET = process.env.JWT_SECRET;

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

// 4. USUWANIE LEKU (DELETE /api/medications/:id)
app.delete('/api/medications/:id', authenticateToken, (req, res) => {
    const sql = 'DELETE FROM medications WHERE id = ? AND userId = ?';

    db.run(sql, [req.params.id, req.user.userId], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: 'Nie znaleziono leku lub brak uprawnień.' });
        res.json({ message: 'Lek usunięty.' });
    });
});

// REJESTRACJA (POST /api/register)
app.post('/api/register', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email i hasło są wymagane!' });
    }

    try {
        // Hashowanie hasła o sile 10
        const hashedPassword = await bcrypt.hash(password, 10);

        // Zapis do bazy
        const sql = 'INSERT INTO users (email, password) VALUES (?, ?)';
        db.run(sql, [email, hashedPassword], function(err) {
            if (err) {
                // Unikalny email
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

// Uruchomienie serwera
app.listen(PORT, () => {
    console.log(`Serwer PILL4U działa na porcie http://localhost:${PORT}`);
});