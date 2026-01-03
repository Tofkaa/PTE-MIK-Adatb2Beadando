# Nyelv Manager - Oracle PL/SQL Learning Management System (LMS)

Ez a projekt egy robusztus, Oracle Database alapu backend rendszer egy nyelvtanulo alkalmazashoz. A rendszer teljes koru funkcionalitast biztosit felhasznalok kezelesere, tananyagok szervezesere, gamifikaciora (XP, Streak, Achievements), osztalytermek kezelesere es adminisztraciora.


## Fobb Funkciok

### Felhasznalok es Gamifikacio
* Profilozas: Regisztracio, szerepkorok (ADMIN, TEACHER, STUDENT).
* Progress Tracking: XP gyujtes, Napi szeriak (Streak) szamitasa, Szintek.
* Achievements: Automatikus kituntetesek (pl. "Eltanulo") feltetelek alapjan, idempotens kiosztassal.

### Oktatasmenedzsment
* Hierarchikus Tananyag: Temakorok -> Leckek -> Gyakorlatok.
* Osztalytermek: Tanarok altal kezelt csoportok, diakok felvetele, aktivitas figyelese.
* Eredmenyek: Tesztek kitoltese, pontozas, idomeres.

### Challenge Rendszer (PvP)
* Felhasznalok kozotti parbajok.
* Statuszkezeles (PENDING -> COMPLETED).
* Gyoztes kihirdetese es validalasa (pl. onkihivas tiltasa).

## Technikai Architektura

A rendszer fejlesztesekor kiemelt figyelmet forditottunk az ipari sztenderdekre:

1. Kozpontositott Hibakezeles (pkg_exception_handler):
   - Megkulonbozteti a Sajat Hibakat (pl. RECORD_NOT_FOUND -20001) a Rendszerhibaktol.
   - A rendszerhibakat (pl. ORA-xxxxx) becsomagolja, es autonom tranzakcioban naplozza az error_log tablaba.
   - A sajat hibakat tiszta uzenettel tovabbdobja a kliensnek.

2. Auditalas es Biztonsag:
   - History Tablak (02_*.sql, 13_*.trg): Minden modositas (INSERT, UPDATE, DELETE) triggereken keresztul verziozva mentodik.
   - Admin Logs: A kritikus muveletek (pl. felfuggesztes) kulon adminisztratori naploba kerulnek.

3. Adatintegritas:
   - Silent Failure Elkerulese: Minden modosito eljaras ellenorzi az SQL%ROWCOUNT-ot.
   - Tranzakciokezeles: A logikai csomagokban nincs COMMIT (kiveve a Job-okat), a vezerles a hivo fel felelossege.

4. Automatizalas:
   - DBMS_SCHEDULER Job: Ejszakai karbantartas fut (15_job_daily_maintenance.sql), ami torli a regi logokat es kezeli az inaktiv felhasznalokat.

## Telepitesi Utmutato

A rendszert az alabbi sorrendben kell telepiteni a mellekelt SQL scriptek futtatasaval. A szamozas (00-18) jeloli a fuggosegi sorrendet.

### 1. Sema es Alapok
* 00_create_commands.sql: Alap tablak es szekvenciak letrehozasa.
* 01_types.sql: Objektum tipusok (Table functions, JSON tipusok).
* 02_*.sql fajlok: History tablak letrehozasa (pl. 02_users_h.sql, 02_lessons_h.sql, stb.).
* 03_vw_*.sql fajlok: Nezetek (pl. 03_vw_user_progress_overview.sql, stb.).

### 2. PL/SQL Csomagok (Logika)
A csomagokat (Packages) az alabbi sorrendben forditsuk:

* 04_pkg_err_log.pck: Autonom naplozas.
* 05_pkg_exception_handler.pck: Kozponti hibakezelo.
* 06_pkg_progress_tracking.pck: XP es eredmenyek.
* 07_pkg_admin_tools.pck: Adminisztracio es riportok.
* 08_pkg_user_management.pck: User CRUD.
* 09_pkg_lesson_management.pck: Tananyag CRUD.
* 10_pkg_classroom_management.pck: Osztalytermek.
* 11_pkg_challenge_system.pck: Kihivasok.
* 12_pkg_achievements.pck: Kituntetesek.

### 3. Triggerek es Indexek
* 13_trg_*.trg fajlok: Futtassa le az osszes trigger fajlt (pl. 13_trg_users_bi.trg, 13_trg_users_h.trg, stb.).
* 14_indexes.sql: Teljesitmenyoptimalizalo indexek.

### 4. Automatizalas es Adatok
* 15_job_daily_maintenance.sql: Karbantarto job beutemezese.
* 16_teszt_adat_loader.sql: Smart Seed Script. Dinamikusan tolti fel a rendszert tesztadatokkal (Admin, Tanarok, Diakok, Leckek).

### 5. Teszteles
* 17_teszt_script1.sql: Rendszer Integritas Teszt. Ez a script ellenorzi a "Happy Path" eseteket es a hibaagakat (pl. duplikalt email kezeles).
* 18_teszt_script2.sql: Log Validacio. Ez a script ellenorzi, hogy a hibak es admin muveletek sikeresen bekerultek-e a naplo tablakba.

## Adatbazis Statisztikak (Views)

A rendszer telepitese utan az alabbi nezetek nyujtanak betekintest az adatokba:
* vw_user_progress_overview: Ranglista XP alapjan.
* vw_lesson_performance_report: Leckek nehezsege es kitoltesi aranyok.
* vw_classroom_member_stats: Tanarok szamara reszletes osztalystatisztika.
