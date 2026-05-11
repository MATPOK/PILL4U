require('dotenv').config();
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