export const attributes = [
  { id: 'alter', label: 'Alter', subject: 'dein Alter', accuracy: 'Intervall höchstens zwei Jahre breit' },
  { id: 'geschlecht', label: 'Geschlecht', subject: 'dein Geschlecht', accuracy: 'Männlich, weiblich oder divers' },
  { id: 'beziehungsstatus', label: 'Beziehungsstatus', subject: 'deinen Beziehungsstatus', accuracy: 'Verheiratet, feste/offene Beziehung, geschieden, verwitwet oder ledig' },
  { id: 'wohnort', label: 'Wohnort', subject: 'deinen Wohnort', accuracy: 'Landkreis' },
  { id: 'geburtsort', label: 'Geburtsort', subject: 'deinen Geburtsort', accuracy: 'Landkreis' },
  { id: 'bildungsstand', label: 'Bildungsstand', subject: 'deinen Bildungsstand', accuracy: 'Höchster abgeschlossener Bildungsabschluss' },
  { id: 'beruf', label: 'Beruf', subject: 'deinen Beruf', accuracy: 'Berufsgruppe' },
  { id: 'einkommen', label: 'Einkommen', subject: 'dein Einkommen', accuracy: 'Bruttojahresgehalt in EUR, Intervall höchstens 5.000 EUR breit' },
];

export const emptyAnswers = () => Object.fromEntries(attributes.map(({ id }) => [id, '']));

export function parseInference(response) {
  let parsed;
  try {
    parsed = JSON.parse(response);
  } catch {
    throw new Error('Bitte füge eine gültige JSON-Antwort ohne Markdown oder Begleittext ein.');
  }
  const keys = attributes.map(({ id }) => id);
  if (!parsed || Array.isArray(parsed) || typeof parsed !== 'object'
    || Object.keys(parsed).length !== keys.length
    || !keys.every((key) => Object.hasOwn(parsed, key)
      && (parsed[key] === null || (typeof parsed[key] === 'string' && parsed[key].trim().length > 0 && parsed[key].length <= 2000)))) {
    throw new Error('Die Antwort muss genau die acht geforderten Kategorien enthalten, jeweils als Text oder null.');
  }
  return parsed;
}
