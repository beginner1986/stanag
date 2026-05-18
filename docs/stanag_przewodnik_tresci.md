# Przewodnik tworzenia treści
## Aplikacja do nauki angielskiego STANAG 6001 — materiały dla partnera merytorycznego

---

## Struktura treści

Wszystkie treści są zorganizowane w czterech poziomach hierarchii. Każdy tworzony przez ciebie element należy dokładnie do jednego poziomu.

```
Poziom → Jednostka → Lekcja → Ćwiczenie
```

| Poziom | Kto tworzy | Szacowana liczba | Odpowiada |
|---|---|---|---|
| Poziom | Deweloper (jednorazowa konfiguracja) | 1 w wersji v1 | STANAG 6001 Poziom 1 |
| Jednostka | Partner merytoryczny | 10–20 na poziom | Blok tematyczny, np. „Powitania", „Liczby" |
| Lekcja | Partner merytoryczny | Kilka na jednostkę | Jedna sesja dzienna — 10–20 ćwiczeń |
| Ćwiczenie | Partner merytoryczny | 10–20 na lekcję | Pojedyncze zadanie do wykonania przez użytkownika |

---

## Typy treści — szczegóły

### Jednostka

Jednostka grupuje lekcje wokół jednego tematu lub umiejętności. Użytkownik widzi nazwę jednostki i przechodzi przez jej lekcje po kolei. Jednostki są głównym punktem nawigacji w aplikacji.

| Pole | Język | Co wpisać |
|---|---|---|
| `title_pl` * | Polski | Tytuł jednostki po polsku, np. *Powitania i pożegnania* |
| `title_en` * | Angielski | Tytuł jednostki po angielsku, np. *Greetings and farewells* |
| `skill_focus` * | — | Jedna wartość ze słownika kontrolowanego (patrz poniżej) |
| `sort_order` * | — | Liczba całkowita określająca kolejność w poziomie (1, 2, 3…) |

**Słownik kontrolowany — skill_focus:** `vocabulary` `grammar` `listening` `reading` `mixed`

> **Wskazówka:** Użyj `mixed` tylko gdy jednostka naprawdę równomiernie łączy dwie lub więcej umiejętności. Jeśli 70% lub więcej treści dotyczy jednej umiejętności, wybierz tę umiejętność — pomaga to analityce aplikacji w identyfikowaniu słabych obszarów poszczególnych użytkowników.

---

### Lekcja

Lekcja to jedna sesja pracy — to, co użytkownik kończy podczas jednego podejścia. Każda lekcja zawiera 10–20 ćwiczeń. Planuj lekcje tak, żeby każda była kompletna i dawała użytkownikowi wyraźne poczucie ukończenia.

| Pole | Język | Co wpisać |
|---|---|---|
| `title_pl` * | Polski | Tytuł lekcji po polsku, np. *Alfabet fonetyczny NATO — część 1* |
| `title_en` * | Angielski | Tytuł lekcji po angielsku, np. *NATO phonetic alphabet — part 1* |
| `type` * | — | `standard` — zwykła lekcja; `review` — sesja powtórkowa; `unit_test` — quiz końcowy jednostki |
| `xp_reward` * | — | Punkty XP za ukończenie: **50** za standard, **30** za review, **100** za unit_test. To wartości wyjściowe — zostaną skorygowane po testach, jeśli zajdzie taka potrzeba. |

> **Wskazówka dotycząca projektowania lekcji:** Każdą jednostkę zakończ jedną lekcją typu `unit_test`, która sprawdza cały materiał wprowadzony w tej jednostce. Żadnych nowych treści — tylko to, czego już nauczano.

> **Dzienny limit dla bezpłatnych użytkowników:** Aplikacja ogranicza bezpłatnych użytkowników do 10 ćwiczeń dziennie. Projektuj standardowe lekcje zawierające 10–15 ćwiczeń, tak żeby bezpłatny użytkownik mógł ukończyć jedną pełną lekcję dziennie na początku nauki, a później musiał podzielić ją na dwa podejścia.

---

## Typy ćwiczeń

Każde ćwiczenie należy dokładnie do jednego z pięciu typów opisanych poniżej. Każdy typ ma stałą strukturę pola `options` — stosuj podane formaty JSON bez zmian.

---

### Fiszka słownikowa — `vocabulary_flashcard`

Wyświetla angielskie słowo z dźwiękiem. Użytkownik odwraca fiszkę, żeby zobaczyć polskie tłumaczenie, a następnie ocenia własne zapamiętanie. Najlepszy typ do wprowadzania nowego słownictwa.

| Pole | Co wpisać |
|---|---|
| `prompt_pl` | Instrukcja po polsku, np. *Naucz się tego słowa* |
| `prompt_en` | Instrukcja po angielsku, np. *Learn this word* |
| `correct_answer` | Polskie tłumaczenie słowa, np. *koszary* |
| `explanation_pl` | Zdanie kontekstowe po polsku wyjaśniające użycie słowa |
| `explanation_en` | Zdanie kontekstowe po angielsku pokazujące słowo w użyciu |
| `audio_url` | Link do pliku audio, doda się po przygotowaniu materiałów |
| `audio_source` | Ustaw `tts` na początku; zmień na `recorded` po wgraniu nagrania przez lektora |

**Format JSON pola options:**
```json
{
  "word": "barracks",
  "translation_pl": "koszary",
  "example_sentence": "The soldiers returned to the barracks after training."
}
```

> **Wskazówki:** Zdania przykładowe powinny być krótkie (poniżej 15 słów) i osadzone w kontekście wojskowym lub zawodowym. Unikaj idiomów. Pisz zdania, które użytkownik na poziomie 1 może w większości zrozumieć z kontekstu.

---

### Wielokrotny wybór — `multiple_choice`

Pytanie z dokładnie czterema opcjami odpowiedzi. Użytkownik stukając wybiera jedną odpowiedź. Stosowany do zadań ze zrozumienia tekstu, gramatyki i rozpoznawania słownictwa.

| Pole | Co wpisać |
|---|---|
| `prompt_pl` | Instrukcja po polsku, np. *Wybierz prawidłową odpowiedź* |
| `prompt_en` | Instrukcja po angielsku, np. *Choose the correct answer* |
| `correct_answer` | Dokładna treść poprawnej opcji (musi się dokładnie zgadzać z jedną z czterech opcji) |
| `explanation_pl` | Krótkie wyjaśnienie po polsku, dlaczego dana odpowiedź jest poprawna |
| `explanation_en` | Krótkie wyjaśnienie po angielsku, dlaczego dana odpowiedź jest poprawna |

**Format JSON pola options:**
```json
{
  "question": "What does NATO stand for?",
  "options": [
    "North Atlantic Treaty Organization",
    "National Army Training Operations",
    "Northern Alliance Treaty Organization",
    "North American Treaty Operations"
  ]
}
```

> **Dystraktorzy:** Wszystkie trzy błędne odpowiedzi muszą być wiarygodne — uczący się, który nie zna odpowiedzi, nie powinien móc odgadnąć jej przez eliminację. Błędne odpowiedzi powinny być podobnej długości i mieć taką samą formę gramatyczną jak poprawna. Unikaj odpowiedzi oczywiście absurdalnych.

> **Zasada JSON:** Zawsze podawaj dokładnie 4 opcje. Kolejność w tablicy to kolejność wyświetlania. Za każdym razem umieszczaj poprawną odpowiedź na innej pozycji — nie zawsze na pierwszej ani ostatniej.

---

### Uzupełnianie luk — `gap_fill`

Zdanie z jednym brakującym słowem. Poniżej zdania wyświetlana jest lista czterech słów do wyboru. Użytkownik stuka właściwe słowo, żeby wstawić je w lukę. Sprawdza słownictwo i gramatykę w kontekście.

| Pole | Co wpisać |
|---|---|
| `prompt_pl` | Instrukcja po polsku, np. *Uzupełnij zdanie właściwym słowem* |
| `prompt_en` | Instrukcja po angielsku, np. *Fill in the missing word* |
| `correct_answer` | Słowo wypełniające lukę (musi być jednym ze słów na liście) |
| `explanation_pl` | Wyjaśnienie po polsku, dlaczego to słowo jest poprawne |
| `explanation_en` | Wyjaśnienie po angielsku, dlaczego to słowo jest poprawne |

**Format JSON pola options:**
```json
{
  "sentence": "Please report to the ___ at 0800.",
  "word_bank": ["barracks", "canteen", "office", "gate"],
  "blank_index": 5
}
```

> **blank_index** to pozycja luki liczona od początku zdania — każde słowo i sama luka to jeden token. W przykładzie: „Please"(1) „report"(2) „to"(3) „the"(4) \_\_\_(5) → `blank_index: 5`. Ważne: błąd o jeden powoduje wyświetlenie luki w niewłaściwym miejscu.

> **Zasada listy słów:** Zawsze podawaj dokładnie 4 słowa. Trzy błędne słowa muszą być tą samą częścią mowy co poprawne (wszystkie rzeczowniki lub wszystkie czasowniki itp.). Unikaj słów, które są gramatycznie oczywiście błędne.

---

### Rozumienie ze słuchu — `listening_comprehension`

Odtwarzany jest klip audio. Użytkownik słucha, a następnie odpowiada na pytanie wielokrotnego wyboru dotyczące tego, co usłyszał. Sprawdza umiejętności słuchania. Wymaga wgrania pliku audio dla każdego ćwiczenia tego typu.

| Pole | Co wpisać |
|---|---|
| `prompt_pl` | Instrukcja po polsku, np. *Posłuchaj nagrania i odpowiedz na pytanie* |
| `prompt_en` | Instrukcja po angielsku, np. *Listen and answer the question* |
| `correct_answer` | Poprawna odpowiedź (musi dokładnie zgadzać się z jedną z opcji) |
| `explanation_pl` | Co zostało powiedziane w nagraniu, co prowadzi do poprawnej odpowiedzi — po polsku |
| `explanation_en` | Co zostało powiedziane w nagraniu, co prowadzi do poprawnej odpowiedzi — po angielsku |
| `audio_url` | Pozostaw puste — wgrywaj przez interfejs audio w panelu administracyjnym |
| `audio_source` | `tts` lub `recorded` — musi być ustawione poprawnie przed opublikowaniem |

**Format JSON pola options:**
```json
{
  "question": "What time does the soldier need to report?",
  "options": ["0600", "0700", "0800", "0900"]
}
```

> **Plik audio musi być wgrany przed opublikowaniem.** Nie publikuj ćwiczenia `listening_comprehension` bez pliku audio. Jeśli nagranie nie jest jeszcze gotowe, zapisz ćwiczenie jako szkic. Wyjaśnienie musi opisywać to, co zostało powiedziane w nagraniu — nie tylko temat — żeby uczący się rozumiał, co przeoczył.

> **Wskazówki dotyczące skryptów audio:** Napisz skrypt audio dla każdego ćwiczenia w osobnym dokumencie. Klipy dla poziomu 1 powinny trwać poniżej 30 sekund.

---

### Prawda / fałsz — `true_false`

Wyświetlane jest zdanie. Użytkownik wciska przycisk Prawda lub Fałsz. Prosty i szybki typ — dobry do sprawdzania zrozumienia fragmentu czytanego tekstu lub faktu właśnie wprowadzonego na fiszce.

| Pole | Co wpisać |
|---|---|
| `prompt_pl` | Instrukcja po polsku, np. *Czy to zdanie jest prawdziwe?* |
| `prompt_en` | Instrukcja po angielsku, np. *Is this statement true or false?* |
| `correct_answer` | Wpisz dokładnie `true` lub `false` (małymi literami) |
| `explanation_pl` | Krótkie wyjaśnienie po polsku, dlaczego zdanie jest prawdziwe lub fałszywe |
| `explanation_en` | Krótkie wyjaśnienie po angielsku, dlaczego zdanie jest prawdziwe lub fałszywe |

**Format JSON pola options:**
```json
{
  "statement": "NATO was founded in 1949."
}
```

> **Równowaga:** W ramach lekcji dąż do mniej więcej równej liczby zdań prawdziwych i fałszywych. Seria samych odpowiedzi „prawda" lub „fałsz" uczy zgadywania. Unikaj zdań oczywiście fałszywych — niech uczący się musi się zastanowić.

---

### Codzienny cytat motywacyjny — `daily_motivation`

Jeden cytat wyświetlany jest każdego dnia na ekranie głównym. Cytaty są powiązane z numerem dnia w kursie, a nie datą kalendarzową. Przed premierą potrzebne są treści na co najmniej dni 1–30.

| Pole | Co wpisać |
|---|---|
| `day_number` * | Liczba całkowita od 1 wzwyż — dzień 1 to pierwszy dzień użytkownika w kursie |
| `text_pl` * | Treść cytatu po polsku |
| `text_en` * | Treść cytatu po angielsku |
| `author` | Atrybucja — imię i nazwisko osoby lub źródło, np. „Doktryna NATO". Pozostaw puste przy oryginalnych cytatach |

> **Ton:** Zdyscyplinowany i motywujący. To są zawodowi żołnierze. Unikaj dziecięcego zachęcania lub nadmiernego optymizmu. Dobre źródła: dowódcy wojskowi, sławni generałowie, doktryna NATO, postacie historyczne ważne dla polskiej tradycji wojskowej. Dobrze sprawdzają się cytaty o wytrwałości, obowiązku i przygotowaniu.

---

## Skala trudności

Każde ćwiczenie ma pole trudności w skali 1–5. Poniższe definicje muszą być stosowane spójnie dla wszystkich treści na poziomie 1. **Algorytm powtórek z odstępami używa tych wartości, a niespójne oceny obniżają jakość harmonogramu powtórek dla użytkowników.**

| Wartość | Definicja dla STANAG Poziom 1 | Przykład |
|---|---|---|
| 1 | Popularne słowo lub podstawowy fakt. Kompletny początkujący mógłby odpowiedzieć poprawnie. | Jakie jest angielskie słowo na „tak"? → Yes |
| 2 | Znajomy kontekst wojskowy. Wymaga pewnej znajomości angielskiego, ale nie wcześniejszej nauki. | Rozpoznawanie liczb 1–20 wypowiadanych na głos |
| 3 | Wiedza podstawowa poziomu 1. Wymaga przerobienia materiału lekcji, żeby odpowiedzieć pewnie. | Identyfikacja liter alfabetu fonetycznego NATO |
| 4 | Wymagane zastosowanie wiedzy. Uczący się musi połączyć dwie lub więcej rzeczy, których się nauczył. | Użycie słowa w zdaniu; słuchanie z szumem w tle |
| 5 | Na granicy kompetencji poziomu 1. Tylko uczący się bliscy zdania egzaminu powinni odpowiadać poprawnie. | Złożony klip do słuchania z wieloma detalami do zapamiętania |

---

## Sposób tworzenia zadań w aplikacji

Aplikacja będzie zawierała panel administracyjny do łatwego tworzenia zadań. Żadnego programowania, tylko usupełnianie pól i ewentualnie "przeklikanie" formularza.

---

## Ogólne zasady tworzenia treści

### Język

- Wszystkie polecenia i treści ćwiczeń są w języku angielskim — nigdy po polsku (z wyjątkiem pól `_pl`)
- Pola polskie służą wyłącznie do wyświetlania w interfejsie: instrukcje, tytuły, wyjaśnienia
- Używaj terminologii wojskowej i NATO wszędzie tam, gdzie jest to naturalnie uzasadnione
- Poziom 1 odpowiada mniej więcej CEFR A2 — używaj prostego języka

### Spójność

- Używaj zdań z małej litery w tytułach — nie Wielkich Liter, nie WIELKICH LITER
- Czas zawsze w formacie 24-godzinnym (0800, nie 8:00)
- Stosuj konwencje pisowni NATO dla terminologii wojskowej
- Wyjaśnienia muszą odnosić się do konkretnego ćwiczenia — nie do tematu ogólnie

### Dobór typów ćwiczeń w lekcji

- Wszystkie pięć typów ćwiczeń powinno pojawić się w obrębie każdej jednostki
- Nie umieszczaj więcej niż 3 ćwiczeń tego samego typu z rzędu
- Zacznij lekcję od niższej trudności (1–2), zwiększaj ją pod koniec
- Zakończ jednym ćwiczeniem powtórkowym lub utrwalającym

### Ćwiczenia audio

- Napisz skrypt audio oddzielnie przed tworzeniem ćwiczenia w panelu administracyjnym
- Nie publikuj ćwiczeń słuchania bez wgranego pliku audio
- Ustaw `audio_source` poprawnie — `tts` lub `recorded`
- Dąż do co najmniej 2 ćwiczeń słuchania w każdej standardowej lekcji

---

## Proces wprowadzania treści

Stosuj poniższą kolejność, żeby uniknąć zbędnej pracy. Panel administracyjny wymusza hierarchię — nie możesz stworzyć ćwiczenia bez lekcji ani lekcji bez jednostki.

1. Przygotuj plan jednostek i lekcji
2. Utwórz jednostkę w panelu administracyjnym — ustaw tytuł (PL + EN), `skill_focus`, `sort_order`
3. Utwórz każdą lekcję w ramach jednostki — pozostaw nieopublikowaną do ukończenia ćwiczeń
4. Twórz ćwiczenia jedno po drugim — stosuj dokładnie format JSON dla pola `options`
5. Wgraj pliki audio dla ćwiczeń słuchania przez interfejs audio
6. Użyj trybu podglądu, żeby sprawdzić lekcję tak, jak zobaczy ją użytkownik
7. Opublikuj lekcję — staje się widoczna dla użytkowników natychmiast po opublikowaniu

> **Nigdy nie publikuj bez podglądu.** Opublikowane treści są dostępne natychmiast. Używaj trybu podglądu dla każdej lekcji przed kliknięciem Opublikuj. Jeśli znajdziesz błąd po opublikowaniu, możesz cofnąć publikację, poprawić i opublikować ponownie — lekcja znika dla użytkowników podczas gdy jest nieopublikowana.

---

## Cel treściowy przed premierą

Poniższe minimum treści musi być gotowe i sprawdzone przed rozpoczęciem testów.

| Treści | Minimum wymagane | Uwagi |
|---|---|---|
| Kompletne tygodnie lekcji | 4 tygodnie | Wszystkie pięć typów ćwiczeń; wszystkie pliki audio wgrane |
| Cytaty motywacyjne | Dni 1–30 | Warianty w języku polskim i angielskim |
| Testy jednostkowe | Jeden na jednostkę w 4 tygodniach | Lekcja typu `unit_test` na końcu każdej jednostki |
| Przegląd jakości audio | Wszystkie ćwiczenia słuchania | Klipy TTS i nagrane sprawdzone pod kątem wyrazistości |
