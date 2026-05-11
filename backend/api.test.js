const request = require('supertest');
const app = require('./index');
const db = require('./db');

const testEmail = `tester_${Date.now()}@test.com`;
const testPassword = 'haslo_testowe';
let token;

describe('PILL4U API - Testy Integracyjne', () => {

    // Scenariusz 1: Rejestracja (ZAKTUALIZOWANE O IMIĘ)
    it('1. Powinien pomyślnie zarejestrować nowego użytkownika', async () => {
        const response = await request(app)
            .post('/api/register')
            .send({ email: testEmail, password: testPassword, name: 'Testowy Przemek' });

        expect(response.statusCode).toBe(201);
        expect(response.body).toHaveProperty('message', 'Rejestracja zakończona sukcesem!');
    });

    // Scenariusz 2: Zabezpieczenie przed duplikatem (ZAKTUALIZOWANE O IMIĘ)
    it('2. Nie powinien pozwolić na rejestrację z tym samym adresem email', async () => {
        const response = await request(app)
            .post('/api/register')
            .send({ email: testEmail, password: testPassword, name: 'Testowy Przemek' });

        expect(response.statusCode).toBe(409);
        expect(response.body).toHaveProperty('error', 'Użytkownik o tym emailu już istnieje.');
    });

    // Scenariusz 3: Logowanie (TUTAJ BEZ ZMIAN, DO LOGOWANIA IMIĘ NIE JEST POTRZEBNE)
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

});