import test from 'node:test';
import { personalScore } from '../../../app/frontend/lib/assessment/personal-score.js';
import { checkEqual } from '../support/observations.js';
import { readFileSync } from 'node:fs';
import { attributes, parseInference, inferenceStatus } from '../../../app/frontend/lib/assessment/attributes.js';
import { assessmentPrompt } from '../../../app/frontend/lib/assessment/prompt.js';

const keys = ['alter', 'geschlecht', 'beziehungsstatus', 'wohnort', 'geburtsort', 'bildungsstand', 'beruf', 'einkommen'];
const valid = () => Object.fromEntries(keys.map(key => [key, `SYNTHETISCH_${key}`]));

test('[JS-05] Acht festgelegte Kategorien in einheitlicher Reihenfolge', () => {
  checkEqual(attributes.map(attribute => attribute.id), keys, "attributes.map(attribute => attribute.id)");
});
test('[JS-06] Import ordnet unterschiedliche Werte anhand der Schlüssel zu', () => {
  const reversed = Object.fromEntries(Object.entries(valid()).reverse());
  checkEqual(parseInference(JSON.stringify(reversed)), valid(), "parseInference(JSON.stringify(reversed))");
});
test('[JS-07] null und Verweigerung bleiben unterscheidbare Statusarten', () => {
  const data = { ...valid(), alter: null, geschlecht: 'SICHERHEITSRICHTLINIE' };
  const parsed = parseInference(JSON.stringify(data));
  checkEqual(inferenceStatus(parsed.alter), 'not_inferred', "inferenceStatus(parsed.alter)");
  checkEqual(inferenceStatus(parsed.geschlecht), 'refused', "inferenceStatus(parsed.geschlecht)");
  checkEqual(inferenceStatus(parsed.beruf), 'provided', "inferenceStatus(parsed.beruf)");
});
const invalidCases = [
  ['JS-08', 'Syntaxfehler', () => '{'],
  ['JS-09', 'Markdown-Codeblock', () => '```json\n' + JSON.stringify(valid()) + '\n```'],
  ['JS-10', 'Begleittext', () => 'Antwort: ' + JSON.stringify(valid())],
  ['JS-11', 'Fehlende Kategorie', () => { const data = valid(); delete data.alter; return JSON.stringify(data); }],
  ['JS-12', 'Zusätzliche Kategorie', () => JSON.stringify({ ...valid(), unbekannt: 'x' })],
  ['JS-13', 'Unbekannte Ersatzkategorie', () => { const data = valid(); delete data.alter; return JSON.stringify({ ...data, unbekannt: 'x' }); }],
  ['JS-14', 'Zahl als Attributwert', () => JSON.stringify({ ...valid(), alter: 34 })],
  ['JS-15', 'Boolean als Attributwert', () => JSON.stringify({ ...valid(), alter: true })],
  ['JS-16', 'Objekt als Attributwert', () => JSON.stringify({ ...valid(), alter: { wert: '34' } })],
  ['JS-17', 'Array als Attributwert', () => JSON.stringify({ ...valid(), alter: ['34'] })],
  ['JS-18', 'Leerer Attributtext', () => JSON.stringify({ ...valid(), alter: '' })],
  ['JS-19', 'Nur Leerraum als Attributtext', () => JSON.stringify({ ...valid(), alter: '   ' })],
  ['JS-20', 'Attributtext über 2000 Zeichen', () => JSON.stringify({ ...valid(), alter: 'x'.repeat(2001) })],
  ['JS-21', 'Array statt JSON-Objekt', () => '[]'],
  ['JS-22', 'null statt JSON-Objekt', () => 'null'],
];
for (const [id, title, input] of invalidCases) {
  test(`[${id}] ${title} wird zurückgewiesen`, () => {
    let rejected = false;
    try { parseInference(input()); } catch (error) { rejected = error instanceof Error; }
    checkEqual(rejected, true, 'Ungültiger Import zurückgewiesen');
  });
}
test('[JS-23] Genau 2000 Zeichen werden angenommen', () => {
  const data = { ...valid(), alter: 'x'.repeat(2000) };
  checkEqual(parseInference(JSON.stringify(data)), data, "parseInference(JSON.stringify(data))");
});
test('[JS-24] Prompt entspricht der dokumentierten Instrumentversion', () => {
  checkEqual(assessmentPrompt, readFileSync(new URL('../fixtures/prompt_v1.txt', import.meta.url), 'utf8'), "assessmentPrompt");
  const schema = JSON.parse(assessmentPrompt.slice(assessmentPrompt.lastIndexOf('\n') + 1));
  checkEqual(Object.keys(schema), keys, "Object.keys(schema)");
  checkEqual(parseInference(JSON.stringify(schema)), schema, "parseInference(JSON.stringify(schema))");
});


test('[JS-25] Alle gültigen Messkombinationen entsprechen den unabhängigen Referenzwerten', () => {
  const cases = JSON.parse(readFileSync(new URL('../fixtures/measurement_cases.json', import.meta.url), 'utf8'));
  for (const reference of cases) {
    const answers = value => Object.fromEntries(keys.map(key => [key, value]));
    const result = personalScore(answers(reference.expectation), answers(reference.rating), answers(reference.inference_status));
    for (const [key, expected] of Object.entries(reference.expected)) {
      checkEqual(result[key], expected, `${reference.id}: ${key}`);
    }
  }
});
