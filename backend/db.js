const sqlite3 = require('sqlite3').verbose();

const db = new sqlite3.Database('./pill4u.sqlite', (err) => {
    if (err) {
        console.error('Błąd połączenia z bazą:', err.message);
    } else {
        console.log('Połączono z bazą danych SQLite.');
    }
});

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT
    )`);
});

module.exports = db;