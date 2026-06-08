// Sekret ustawiamy PRZED załadowaniem aplikacji, żeby testy działały także w CI
// (gdzie nie ma pliku .env). W produkcji JWT_SECRET pochodzi ze środowiska.
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci';

const request = require('supertest');
const app = require('./index');

const testEmail = `tester_${Date.now()}@test.com`;
const testPassword = 'haslo_testowe';
let token;
let createdHistoryId;

describe('PILL4U API - Testy Integracyjne', () => {

    // Scenariusz 1: Rejestracja
    it('1. Powinien pomyślnie zarejestrować nowego użytkownika', async () => {
        const response = await request(app)
            .post('/api/register')
            .send({ email: testEmail, password: testPassword, name: 'Testowy Przemek' });

        expect(response.statusCode).toBe(201);
        expect(response.body).toHaveProperty('message', 'Rejestracja zakończona sukcesem!');
    });

    // Scenariusz 2: Zabezpieczenie przed duplikatem
    it('2. Nie powinien pozwolić na rejestrację z tym samym adresem email', async () => {
        const response = await request(app)
            .post('/api/register')
            .send({ email: testEmail, password: testPassword, name: 'Testowy Przemek' });

        expect(response.statusCode).toBe(409);
        expect(response.body).toHaveProperty('error', 'Użytkownik o tym emailu już istnieje.');
    });

    // Scenariusz 3: Logowanie
    it('3. Powinien zalogować użytkownika i zwrócić token JWT', async () => {
        const response = await request(app)
            .post('/api/login')
            .send({ email: testEmail, password: testPassword });

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty('token');

        token = response.body.token;
    });

    // Scenariusz 4: Ochrona tras (Brak tokena)
    it('4. Powinien odrzucić zapytanie o leki, gdy brakuje tokena', async () => {
        const response = await request(app).get('/api/medications');

        expect(response.statusCode).toBe(401);
        expect(response.body).toHaveProperty('error', 'Brak tokena, dostęp zabroniony.');
    });

    // Scenariusz 5: Dodawanie leku (Z tokenem)
    it('5. Powinien dodać nowy lek, jeśli podano poprawny token JWT', async () => {
        const response = await request(app)
            .post('/api/medications')
            .set('Authorization', `Bearer ${token}`)
            .send({
                name: 'Witamina C',
                dosage: '1000mg',
                time: '09:00',
                days: 'Pn,Śr,Pt'
            });

        expect(response.statusCode).toBe(201);
        expect(response.body).toHaveProperty('message', 'Lek dodany pomyślnie!');
    });

    // Scenariusz 6: Walidacja - lek bez nazwy
    it('6. Powinien odrzucić dodanie leku bez nazwy (400)', async () => {
        const response = await request(app)
            .post('/api/medications')
            .set('Authorization', `Bearer ${token}`)
            .send({ name: '', dosage: '100mg', time: '08:00', days: 'Pn' });

        expect(response.statusCode).toBe(400);
        expect(response.body).toHaveProperty('error');
    });

    // Scenariusz 7: Odrzucenie nieprawidłowego tokena (403)
    it('7. Powinien odrzucić zapytanie z nieprawidłowym tokenem', async () => {
        const response = await request(app)
            .get('/api/medications')
            .set('Authorization', 'Bearer niepoprawny.token.jwt');

        expect(response.statusCode).toBe(403);
    });

    // Scenariusz 8: Dodanie wpisu do historii
    it('8. Powinien dodać wpis do historii (status TAKEN)', async () => {
        const response = await request(app)
            .post('/api/history')
            .set('Authorization', `Bearer ${token}`)
            .send({
                medicationId: 1,
                medicationName: 'Witamina C',
                status: 'TAKEN',
                takenAt: new Date().toISOString()
            });

        expect(response.statusCode).toBe(201);
        expect(response.body).toHaveProperty('id');
        createdHistoryId = response.body.id;
    });

    // Scenariusz 9: Walidacja statusu historii
    it('9. Powinien odrzucić wpis historii z niepoprawnym statusem (400)', async () => {
        const response = await request(app)
            .post('/api/history')
            .set('Authorization', `Bearer ${token}`)
            .send({ medicationId: 1, medicationName: 'X', status: 'NIEZNANY' });

        expect(response.statusCode).toBe(400);
    });

    // Scenariusz 10: Pobranie historii
    it('10. Powinien zwrócić listę wpisów historii użytkownika', async () => {
        const response = await request(app)
            .get('/api/history')
            .set('Authorization', `Bearer ${token}`);

        expect(response.statusCode).toBe(200);
        expect(Array.isArray(response.body)).toBe(true);
        expect(response.body.length).toBeGreaterThan(0);
    });

    // Scenariusz 11: Statystyki historii
    it('11. Powinien zwrócić statystyki ze skutecznością', async () => {
        const response = await request(app)
            .get('/api/history/stats')
            .set('Authorization', `Bearer ${token}`);

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty('taken');
        expect(response.body).toHaveProperty('missed');
        expect(response.body).toHaveProperty('effectiveness');
    });

    // Scenariusz 12: Usunięcie wpisu historii (cofnięcie akcji)
    it('12. Powinien usunąć wcześniej dodany wpis historii', async () => {
        const response = await request(app)
            .delete(`/api/history/${createdHistoryId}`)
            .set('Authorization', `Bearer ${token}`);

        expect(response.statusCode).toBe(200);
        expect(response.body).toHaveProperty('message', 'Cofnięto wpis w historii.');
    });

    // Zamykamy połączenie z bazą, żeby Jest nie zawisł po testach.
    afterAll((done) => {
        const db = require('./db');
        db.close(() => done());
    });
});
