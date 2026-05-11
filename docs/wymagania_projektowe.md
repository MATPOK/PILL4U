# Dokumentacja Projektowa - PILL4U

## 1. Uzasadnienie: Dlaczego aplikacja wymaga smartfona?
Aplikacja PILL4U rozwiązuje problem regularnego przyjmowania leków, co z definicji jest czynnością wykonywaną w różnych miejscach (w domu, w pracy, w podróży). Stworzenie wersji desktopowej mijałoby się z celem, ponieważ użytkownik musiałby siedzieć przy komputerze w momencie, gdy wypada pora wzięcia leku. Zastosowanie smartfona pozwala na wykorzystanie **natywnych powiadomień push (z wibracją i dźwiękiem)**, które docierają do użytkownika natychmiast. Ponadto, aplikacja korzysta z **lokalnej pamięci urządzenia (offline-first)**, co pozwala na sprawdzenie harmonogramu i odznaczenie wzięcia leku nawet w miejscach bez zasięgu Internetu (np. w pociągu), co na desktopie byłoby niemożliwe.

## 2. MVP vs Funkcje dodatkowe
* **MVP (Minimum Viable Product):** Rejestracja i logowanie użytkownika, dodawanie nowego leku (nazwa, dawka, czas, częstotliwość), widok listy leków na dzisiejszy dzień, możliwość odznaczenia leku jako "Wzięty" lub "Pominięty".
* **Funkcje dodatkowe:** Lokalne powiadomienia push przypominające o dawce, działanie aplikacji w trybie offline z późniejszą synchronizacją z serwerem, generowanie statystyk z ostatnich 7 dni (wykresy postępu), wsparcie dla ciemnego motywu (Dark Mode) dla osób niedowidzących.

## 3. Lista 15 User Stories (Wymagania)
1. Jako użytkownik chcę założyć konto, aby moje dane były bezpieczne.
2. Jako użytkownik chcę się zalogować przy użyciu emaila i hasła.
3. Jako zalogowany użytkownik chcę móc się wylogować z urządzenia.
4. Jako użytkownik chcę dodać nowy lek podając jego nazwę, dawkę i godzinę.
5. Jako użytkownik chcę dostać błąd, jeśli spróbuję zapisać lek bez podania nazwy.
6. Jako użytkownik chcę widzieć listę moich leków zaplanowanych na dzisiejszy dzień.
7. Jako użytkownik chcę kliknąć przycisk "Wzięty", aby potwierdzić zażycie dawki.
8. Jako użytkownik chcę kliknąć "Pominięty", jeśli zapomniałem wziąć lek.
9. Jako użytkownik chcę otrzymywać systemowe powiadomienie push o określonej godzinie.
10. Jako użytkownik chcę widzieć listę leków nawet wtedy, gdy nie mam zasięgu (Offline).
11. Jako użytkownik chcę, aby po odzyskaniu Internetu moje kliknięcia "Wzięty" zsynchronizowały się z bazą.
12. Jako użytkownik chcę widzieć historię moich leków z ostatnich 7 dni.
13. Jako użytkownik chcę widzieć procentowy wykres mojego przestrzegania harmonogramu leczenia.
14. Jako użytkownik chcę móc włączyć Tryb Ciemny (Dark Mode), aby nie męczyć wzroku.
15. Jako użytkownik chcę usunąć lek z listy, jeśli zakończyłem kurację.

## 4. Checklista Testów Akceptacyjnych (UAT)
* [ ] **T01:** Użytkownik potrafi poprawnie utworzyć konto i się zalogować (działa token JWT).
* [ ] **T02:** Poprawne dodanie leku skutkuje jego natychmiastowym pojawieniem się na głównym ekranie.
* [ ] **T03:** O godzinie przypisanej do leku, telefon odtwarza wibrację/dźwięk i wyświetla powiadomienie push.
* [ ] **T04:** Po kliknięciu "Wzięty", status zapisuje się poprawnie, co aktualizuje wykres w "Historii".
* [ ] **T05:** Przełączenie telefonu w tryb samolotowy (brak internetu) nie blokuje wyświetlania listy leków na dziś.
