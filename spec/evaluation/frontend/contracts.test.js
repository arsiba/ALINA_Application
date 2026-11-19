import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { attributes, parseInference, inferenceStatus } from '../../../app/frontend/lib/assessment/attributes.js';
import { assessmentPrompt } from '../../../app/frontend/lib/assessment/prompt.js';

const keys = ['alter', 'geschlecht', 'beziehungsstatus', 'wohnort', 'geburtsort', 'bildungsstand', 'beruf', 'einkommen'];
const valid = () => Object.fromEntries(keys.map(key => [key, `SYNTHETISCH_${key}`]));

test('[JS-05] Acht festgelegte Kategorien in einheitlicher Reihenfolge', () => {
  assert.deepEqual(attributes.map(attribute => attribute.id), keys);
});
test('[JS-06] Import ordnet unterschiedliche Werte anhand der Schlüssel zu', () => {
  const reversed = Object.fromEntries(Object.entries(valid()).reverse());
  assert.deepEqual(parseInference(JSON.stringify(reversed)), valid());
});
test('[JS-07] null und Verweigerung bleiben unterscheidbare Statusarten', () => {
  const data = { ...valid(), alter: null, geschlecht: 'SICHERHEITSRICHTLINIE' };
  const parsed = parseInference(JSON.stringify(data));
  assert.equal(inferenceStatus(parsed.alter), 'not_inferred');
  assert.equal(inferenceStatus(parsed.geschlecht), 'refused');
  assert.equal(inferenceStatus(parsed.beruf), 'provided');
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
    assert.throws(() => parseInference(input()), Error);
  });
}
test('[JS-23] Genau 2000 Zeichen werden angenommen', () => {
  const data = { ...valid(), alter: 'x'.repeat(2000) };
  assert.deepEqual(parseInference(JSON.stringify(data)), data);
});
test('[JS-24] Prompt entspricht der dokumentierten Instrumentversion', () => {
  assert.equal(assessmentPrompt, readFileSync(new URL('../fixtures/prompt_v1.txt', import.meta.url), 'utf8'));
  const schema = JSON.parse(assessmentPrompt.slice(assessmentPrompt.lastIndexOf('\n') + 1));
  assert.deepEqual(Object.keys(schema), keys);
  assert.deepEqual(parseInference(JSON.stringify(schema)), schema);
});
