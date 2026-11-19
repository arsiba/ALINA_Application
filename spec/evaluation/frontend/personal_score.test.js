import test from 'node:test';
import { checkEqual } from '../support/observations.js';
import { attributes } from '../../../app/frontend/lib/assessment/attributes.js';
import { personalScore } from '../../../app/frontend/lib/assessment/personal-score.js';

const answers = (value) => Object.fromEntries(attributes.map(({ id }) => [id, value]));

test('[JS-01] Vollständige Übereinstimmung ergibt 100 Prozent, vollständige Abweichung null', () => {
  checkEqual(personalScore(answers('yes'), answers('correct'), answers('provided')).score, 1, "personalScore(answers('yes'), answers('correct'), answers('provided')).score");
  checkEqual(personalScore(answers('yes'), answers('incorrect'), answers('provided')).score, 0, "personalScore(answers('yes'), answers('incorrect'), answers('provided')).score");
});

test('[JS-02] Nicht-Ableitung ist je nach Erwartung Überschätzung oder Übereinstimmung', () => {
  const expected = personalScore(answers('yes'), answers('invalid'), answers('not_inferred'));
  checkEqual(expected.score, 0, "expected.score");
  checkEqual(expected.overestimation_count, 8, "expected.overestimation_count");
  const unexpected = personalScore(answers('no'), answers('invalid'), answers('not_inferred'));
  checkEqual(unexpected.score, 1, "unexpected.score");
  checkEqual(unexpected.agreement_count, 8, "unexpected.agreement_count");
});

test('[JS-03] Gemischter Fall verwendet sechs auswertbare Antworten als gemeinsamen Nenner', () => {
  const expectations = { ...answers('yes'), alter: 'no' };
  const ratings = { ...answers('correct'), geschlecht: 'invalid', beruf: 'invalid', einkommen: 'incorrect', wohnort: 'invalid' };
  const statuses = { ...answers('provided'), geschlecht: 'not_inferred', beruf: 'refused' };
  const result = personalScore(expectations, ratings, statuses);
  checkEqual(result.evaluable_count, 6, "result.evaluable_count");
  checkEqual(result.excluded_count, 2, "result.excluded_count");
  checkEqual(result.not_inferred_count, 1, "result.not_inferred_count");
  checkEqual(result.refused_count, 1, "result.refused_count");
  checkEqual(result.invalid_count, 1, "result.invalid_count");
  checkEqual(result.agreement_count, 3, "result.agreement_count");
  checkEqual(result.score, 0.5, "result.score");
  checkEqual(result.gap_rate, 0.5, "result.gap_rate");
  checkEqual(result.underestimation_rate, 1 / 6, "result.underestimation_rate");
  checkEqual(result.overestimation_rate, 2 / 6, "result.overestimation_rate");
});

test('[JS-04] Vollständig ausgeschlossene Antworten ergeben undefinierte Quoten', () => {
  for (const status of ['refused', 'provided']) {
    const result = personalScore(answers('yes'), answers('invalid'), answers(status));
    checkEqual(result.score, null, "result.score");
    checkEqual(result.gap_rate, null, "result.gap_rate");
    checkEqual(result.evaluable_count, 0, "result.evaluable_count");
  }
});
