# Anforderungsbasierte Evaluation

Die Suite bildet die technische Evaluation aus Kapitel 6 der Bachelorarbeit ab. Sie verwendet ausschließlich synthetische Befragungs- und Inferenzdaten. Vorhandene fachliche Tests wurden in diesen Ordner überführt und um stabile Test-IDs, Anforderungszuordnungen, Importverträge, Promptreferenz, Vorschau-Payload-Vergleich und Prüfung tatsächlicher Rails-Logs ergänzt. Die Testimplementierungen werden nicht parallel in den bisherigen Ordnern weitergeführt.

Die vollständige, ausführliche Tabelle steht in [KRITERIEN.md](KRITERIEN.md). Sie nennt für jeden Test Anforderung, Verfahren, Ausgangszustand, Eingabe, Sollverhalten, Implementierung und Aussagegrenze. [catalog.json](catalog.json) und [requirements.json](requirements.json) sind die maschinenlesbare Grundlage für Tabelle und Konsolenbericht.

## Ausführen

Im Projektverzeichnis:

```bash
bin/evaluate
```

Voraussetzungen sind die installierten Ruby-Abhängigkeiten (`bundle install`), Frontend-Abhängigkeiten (`npm ci --legacy-peer-deps --no-audit --no-fund`), Ruby, Node.js, npm, Git sowie Chromium und ChromeDriver unter `/usr/bin/chromium` bzw. `/usr/bin/chromedriver`. Die konkreten verwendeten Versionen werden pro Lauf erfasst. Der Runner führt `bundle check`, einen Vite-Produktionsbuild und `bin/rails db:prepare` für die **Testdatenbank** aus. Dadurch wird die Anwendung mit gebauten Frontendassets im Browser geprüft. Das ist keine Prüfung eines produktiven Deployments.

Die Ausführung erfolgt in definierter Reihenfolge, nicht parallel. Die Browserprüfungen setzen den tatsächlichen CSS-Viewport über Chromium DevTools und prüfen `innerWidth`/`innerHeight`; eine nominelle äußere Fenstergröße wird dadurch nicht mit der tatsächlich geprüften Breite verwechselt. Dies emuliert weiterhin kein reales Mobilgerät. Jeder Lauf erhält einen neuen Ordner `tmp/evaluation/<UTC-Zeitpunkt>-<Zufall>/`. Der vollständige Pfad wird auf der Konsole angezeigt. Der Runner benötigt einen lokalen TCP-Port für Capybara und Zugriff auf den installierten Browser. Die Tests nutzen Transaktionen und eine lokale SQLite-Testdatenbank; zwei Evaluationsläufe sollen nicht gleichzeitig auf derselben Testdatenbank laufen.

| Datei im Ergebnisordner | Verwendung |
|---|---|
| `AUSWERTUNG.md` | Beobachtete Gesamtzahlen und Einordnung jeder Anforderung für das Ergebniskapitel; ausdrücklich getrennt vom Prüfplan. |
| `protocol.txt` | Lesbares Konsolenprotokoll für den Anhang: Umgebung, Abschnitte, Test-IDs, Anforderungen, Eingaben, Sollverhalten, beobachteter Prüfstatus, Laufzeiten und Nachweisgrenzen. |
| `evaluation.json` | Strukturierte fachliche Ergebnisse pro Test und Anforderung mit Status, Dauer und gegebenenfalls Fehler bzw. Grund für fehlenden Nachweis. |
| `rspec.json` | RSpec-Rohbericht einschließlich der tatsächlichen Example-Positionen und Fehlerdetails. |
| `environment.json` | Zeit, Git-Commit und Änderungsstatus, Ruby-/Rails-/Node-/Browser-/Treiber-/Testframeworkversionen, Instrumentversion, Prompt-Hash, Konfiguration und Umgebungsgrenzen. |
| `source-files.json` | SHA-256 je vorhandener, von Git erfasster oder nicht ignorierter unversionierter Datei. Der Gesamthash in `environment.json` identifiziert auch einen noch nicht committeten Arbeitsstand. |
| `setup.log` | Abhängigkeitsprüfung, Frontendbuild und Vorbereitung der Testdatenbank. |
| `alina-*.png` | Ergänzende Screenshots einzelner Browserzustände. Sie werden erzeugt, aber nicht automatisch visuell bewertet und sind kein eigenständiger Erfüllungsnachweis. |

Die Ergebnisordner liegen im bereits ignorierten `tmp/`. Für die endgültige Abgabe muss der gewählte vollständige Lauf außerhalb temporärer Dateien archiviert werden. Am Laufende wird geprüft, dass das Dateiinventar seit dem Umgebungsnachweis unverändert ist; bei Änderungen bricht der Runner ab. Ein Hash identifiziert einen Arbeitsstand, ersetzt aber kein Archiv: Softwarestand inklusive Testdateien und Lockfiles zusammen mit den Ergebnissen sichern oder committen. Fehlgeschlagene Vorläufe nicht mit dem abschließenden Lauf vermischen. Das Protokoll enthält lokale Pfade und Git-Status; vor einer Veröffentlichung können persönliche Pfadbestandteile geschwärzt werden, ohne Ergebnisse zu verändern.

## Aufbau und Testebenen

| Ordner | Gegenstand |
|---|---|
| `models/` | Messmodell, Vollständigkeit und Datenbankkonsistenz. |
| `services/` | Aggregation, Gewichtung, Instrumentversion und Gruppenfreigabe. |
| `requests/` | HTTP-Schnittstelle, Persistenz, Validierung, Atomarität, Wiederholungen, Logs und Teilnahmeflag. |
| `browser/` | Vollständiger JavaScript-Ablauf, Import, Bewertung, Datenvorschau, Fehler, Abbruch, Ergebnisansicht und Layout. |
| `frontend/` | Direkte Tests des JavaScript-Parsers, Prompts und persönlichen Scores. `javascript_spec.rb` startet je Kriterium genau einen Node-Test und übernimmt dessen Ergebnis in RSpec. |
| `configuration/` | Gültige und ungültige Freigabeschwellen. |
| `limitations/` | Vier ausdrücklich nicht untersuchte Nachweise als übersprungene, begründete RSpec-Beispiele. |
| `fixtures/` | Eingefrorener Referenzprompt für Instrumentversion 1. Bei fachlichen Änderungen Instrumentversion und Referenz bewusst gemeinsam prüfen. |
| `support/` | Browserkonfiguration, fachlicher Formatter, Umgebungsnachweis und Tabellengenerator. |

`bin/test` bleibt der Einstieg für alle lokalen Checks einschließlich RuboCop, Brakeman und Autoloadprüfung. Es wurde auf die neuen Pfade angepasst. `bin/evaluate` erzeugt den fachlichen Evaluationsbericht. Die JavaScript-Tests laufen über den RSpec-Wrapper und werden dabei nicht ein zweites Mal separat gestartet. Linting und statische Sicherheitsanalyse werden nicht als empirische Anforderungsnachweise ausgegeben.

## Was das Protokoll tatsächlich beobachtet

Der Formatter gibt für jeden Prüffall Sollverhalten und Ergebnis aus. „BESTANDEN“ bedeutet, dass alle im Beispiel ausgeführten Assertions erfüllt wurden. Das ist ein beobachtetes Pass/Fail-Ergebnis; der Formatter behauptet keine zusätzlich gemessenen Zahlen. Die angegebenen Kennzahlen sind feste Sollwerte, mit denen die Implementierung verglichen wird. Bei Fehlern erscheinen die tatsächliche Assertion-Fehlermeldung und im RSpec-JSON weitere Details.

„NICHT UNTERSUCHT“ ist ein fehlender Nachweis und kein bestandener Test. Die vier MAN-Fälle werden mit Begründung übersprungen. Der Runner darf bei diesen dokumentierten Grenzen erfolgreich enden. Ein Fehler in einem automatisierten Prüffall führt zu einem Exitcode ungleich null. Das bloße Bestehen der technischen Kriterien wird in der Anforderungsübersicht von nur teilweise geprüften Qualitätsanforderungen unterschieden. Vollständigkeit und Eindeutigkeit der Test-IDs werden gegen den Katalog geprüft; der spezielle Formatter ist deshalb für vollständige Läufe vorgesehen.

Die Datenflussprüfung erfasst die vom Workflow verwendeten `fetch`-Requests, prüft sichtbare Vorschauen, Serverantworten, gespeicherte Datensätze und relevante Rails-Anwendungslogs. Das ist keine vollständige Untersuchung sämtlicher Netzwerkkanäle, Browsererweiterungen oder Hosting-/Proxylogs. Bei Fehler- und Abbruchfällen wird die Kommunikation teilweise gezielt simuliert; dies ist im Testfall benannt. Die Rails-Testumgebung deaktiviert die CSRF-Prüfung.

## Messregeln und unabhängige Sollwerte

Für die Evaluation gelten folgende Entscheidungsregeln. Sie müssen mit Kapitel 4/5 der Arbeit übereinstimmen, bevor Ergebnisse wissenschaftlich interpretiert werden.

| Antwortstatus | Bewertung | Erwartung | Auswertbar? | Ergebnis des Abgleichs |
|---|---|---|---|---|
| `provided` | `correct` | `yes` | Ja | Übereinstimmung |
| `provided` | `correct` | `no` | Ja | Unterschätzung |
| `provided` | `incorrect` | `yes` | Ja | Überschätzung |
| `provided` | `incorrect` | `no` | Ja | Übereinstimmung |
| `not_inferred` | `invalid` | `yes` | Ja | Überschätzung |
| `not_inferred` | `invalid` | `no` | Ja | Übereinstimmung |
| `provided` | `invalid` | beliebig | Nein | Enthaltung / nicht prüfbar |
| `refused` | `invalid` | beliebig | Nein | Sicherheitsverweigerung |

**Wichtig:** Nicht-Ableitung (`null` im Import, `not_inferred` im Datenmodell) ist eine auswertbare Nichterfüllung der erwarteten Ableitung. Sie ist nicht mit einem fehlenden, noch nicht bearbeiteten Antwortstatus (SQL NULL) gleichzusetzen. Sicherheitsverweigerung und Enthaltung werden aus dem Nenner des Abgleichs ausgeschlossen. Die Bewertung `incorrect` bedeutet hier ein negatives selbstberichtetes Ergebnis der Inferenz, keine unabhängig festgestellte Wahrheit über die Person.

Es gelten:

- Abweichungsquote / Awareness-Gap = (Unter- + Überschätzungen) / auswertbare Kategorien.
- Richtungsquoten = jeweilige Richtung / auswertbare Kategorien.
- Persönlicher Score = Übereinstimmungen / auswertbare Kategorien.
- Abdeckungsquote = auswertbare / alle Kategorieantworten.
- Bei null auswertbaren Kategorien sind Abweichungsquote, Richtungsquoten und Score undefiniert (`nil`/`null`), nicht null Prozent.
- Gepoolte Abweichungsquote = Summe aller Abweichungen / Summe aller auswertbaren Kategorien. Der Mittelwert individueller Quoten gewichtet jede auswertbare Person gleich; Personen ohne auswertbare Kategorien gehen nicht in diesen Mittelwert ein.

### Fester gemischter Einzelfall (MOD-03)

| Kategorie | Erwartung | Status | Bewertung | Manuell vorgegebenes Ergebnis |
|---|---|---|---|---|
| Alter | yes | not_inferred | invalid | Überschätzung |
| Geschlecht | no | not_inferred | invalid | Übereinstimmung |
| Beziehungsstatus | no | provided | correct | Unterschätzung |
| Wohnort | yes | provided | incorrect | Überschätzung |
| Geburtsort | yes | provided | correct | Übereinstimmung |
| Bildungsstand | no | provided | incorrect | Übereinstimmung |
| Beruf | yes | refused | invalid | Ausgeschlossen |
| Einkommen | yes | provided | invalid | Ausgeschlossen |

Daraus folgen unabhängig vom Anwendungscode: 6 auswertbare Kategorien, 2 Ausschlüsse, 1 Unterschätzung und 2 Überschätzungen. Die Gap beträgt 3/6 = 0,5; die Richtungsquoten betragen 1/6 und 2/6. Diese festen Werte stehen unmittelbar in den Assertions. Sie werden nicht aus der zu prüfenden Berechnung erzeugt.

### Unterschiedliche Gewichtungen (AGG-04)

| Synthetische Person | Auswertbare Kategorien | Abweichungen | Individuelle Gap |
|---|---|---|---|
| A | 8 | 8 | 1 |
| B | 1 | 0 | 0 |
| Zusammen | 9 | 8 | Gepoolt 8/9 ≈ 0,8889; individuelles Mittel (1 + 0)/2 = 0,5 |

Diese Gegenüberstellung verhindert, dass zwei fachlich unterschiedliche Kennzahlen versehentlich gleich berechnet werden.

## Grundlage für das Evaluationskapitel

Die Evaluation ist eine anforderungsbasierte technische Prüfung des entwickelten Messinstruments. Sie beantwortet, ob festgelegte Eingaben nach den implementierten Messregeln verarbeitet werden und ob die geprüften Abläufe in der dokumentierten Umgebung funktionieren. Sie erhebt keine Awareness-Gap einer realen Stichprobe und validiert weder die psychometrische Güte des Messinstruments noch die Inferenzleistung eines LLMs.

Für den Methodenteil lassen sich vier Prüfbereiche begründen:

1. **Korrektheit der Auswertung:** Model-, Service- und JavaScript-Tests vergleichen Einzel- und Gesamtkennzahlen mit vorher festgelegten Sollwerten. Grenzfälle sind Nicht-Ableitung, Verweigerung, Enthaltung und ein leerer Nenner.
2. **Zuverlässigkeit der Verarbeitung:** Request- und Parsertests variieren Struktur, Vollständigkeit und Datentypen. Gezielte Speicherfehler, wiederholte Übermittlungen und Konflikte prüfen Atomarität und Konsistenz.
3. **Einhaltung des Datenflusses:** Eindeutige synthetische Marker machen konkrete Inferenzinhalte erkennbar. Der Browserablauf, die HTTP-Schnittstelle, die Datenbank und Rails-Logs werden geprüft. Vorschauwerte werden vollständig mit den gesendeten Abschnittspayloads verglichen; Ergebnisfreigabe wird unterhalb, an und oberhalb der Schwelle geprüft.
4. **Durchführbarkeit und Nachvollziehbarkeit:** Browsertests führen den vollständigen Ablauf aus und prüfen Pflichtantworten, Rücknavigation, Fehlerkorrektur, Abbruch, Ergebnisdarstellung und definierte Fensterbreiten.

Im Versuchsaufbau Softwarestand, Instrumentversion, Testdatenprinzip, Sollwertbildung, Testebenen, Browser-/Treiberversion und Umgebung dokumentieren. Dafür stehen `environment.json`, `source-files.json` und die Tabellen bereit. Bei der Ergebnisdarstellung konkrete Anzahlen aus dem **gewählten finalen Lauf** übernehmen, fehlgeschlagene Fälle benennen und offene Nachweise separat ausweisen. Laufzeit ist die Testausführungsdauer, keine gemessene Antwortzeit oder Leistungskennzahl der Anwendung.

Für jede Anforderung sollte die Arbeit zwischen erfüllten technischen Teilkriterien und der gesamten Anforderung unterscheiden. FA-01 bis FA-13 können im Umfang der definierten technischen Fälle beurteilt werden. QA-03 lässt sich hinsichtlich des vereinheitlichten Anwendungsablaufs prüfen. QA-01/02 benötigen einen Zielgruppennutzungstest; QA-04 umfasst zusätzlich methodische Dokumentation und Grenzen externer Modellauskünfte; QA-05 ist hinsichtlich technischer Behandlung geprüft, nicht hinsichtlich empirisch verständlicher Meldungen; QA-06 gilt nur für getestete Umgebungen; QA-07 ist ohne Last-/Betriebsuntersuchung nicht nachgewiesen. Automatisierte Tests rechtfertigen keine pauschale Aussage vollständiger Anonymität oder rechtlicher Konformität.

### Ergänzende Untersuchungen

| Offener Nachweis | Vor Durchführung festlegen | Protokollieren |
|---|---|---|
| MAN-01: selbstständige Nutzung | Zielgruppe, Rekrutierung, Aufgaben, erlaubte Hilfe und Erfolgskriterien | Abschluss, Hilfebedarf, Abbrüche, Missverständnisse; keine künstlich erfundenen Ergebnisse. |
| MAN-02: weitere Browser/Geräte | Konkrete Browser-/OS-/Gerätematrix und Kernabläufe | Versionen, Eingabeart, Darstellungsprobleme und Ergebnis pro Ablauf. |
| MAN-03: Skalierung/Betrieb | Teilnehmerzahl, Parallelität, Dauer, Lastprofil und akzeptierte Fehlerrate/Antwortzeiten; separat Betreuungsaufwand | Ressourcen, Latenzen, Fehler und tatsächliche Wartungs-/Betreuungszeit. Ein Lasttest allein erfüllt QA-07 nicht. |
| MAN-04: echte Modellauskunft | LLM-Anwendung, angezeigtes Modell, Zeitpunkt, zugänglicher Chat-/Memorykontext und Datenschutz bei Dokumentation | Promptversion, direkte Importierbarkeit, notwendige Korrekturen und Abschluss; keine Verallgemeinerung der Inferenzleistung oder Reproduzierbarkeit. |

## Katalog pflegen

Neue Kriterien erhalten eine stabile, eindeutige ID. Testbeschreibung beginnt mit `[ID]`. `catalog.json` enthält zugehörige Anforderungen und Sollverhalten. Bei Änderungen an Anforderungen auch `requirements.json` und die Erläuterungen prüfen. Danach die ausführliche Tabelle neu erzeugen:

```bash
ruby spec/evaluation/support/documentation.rb
```

Die Test-ID wird bei fachlichen Erweiterungen nicht umnummeriert. Änderungen an Sollwerten oder am Referenzprompt müssen fachlich begründet werden; eine Anpassung nur zur Beseitigung eines fehlgeschlagenen Tests ist kein Evaluationsnachweis.

## Lesbares Protokoll in LaTeX einbinden

Das Textprotokoll kann mit `fvextra` umgebrochen in den Anhang eingebunden werden. Den gewählten finalen Bericht zuerst in das Verzeichnis der Arbeit kopieren; der Pfad unten ist ein Beispiel:

```latex
% Präambel
\usepackage{fvextra}

% Anhang
\VerbatimInput[breaklines,breakanywhere,fontsize=\scriptsize]{anhang/evaluation/protocol.txt}
```

Die Datei ist UTF-8. Die Schrift-/LaTeX-Konfiguration der Arbeit muss die deutschen Zeichen unterstützen. Im Kapitel auf den gewählten Lauf und dessen Softwarestand verweisen; Tabellen aus `KRITERIEN.md` beschreiben das Verfahren, Tabellen aus `AUSWERTUNG.md` die tatsächlich beobachteten Ergebnisse.
