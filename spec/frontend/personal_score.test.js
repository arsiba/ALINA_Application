import test from 'node:test';
import assert from 'node:assert/strict';
import { attributes } from '../../app/frontend/lib/assessment/attributes.js';
import { personalScore } from '../../app/frontend/lib/assessment/personal-score.js';

const answers = (value) => Object.fromEntries(attributes.map(({ id }) => [id, value]));

test('complete agreement scores 100 percent and complete disagreement scores zero', () => {
  assert.equal(personalScore(answers('yes'), answers('correct'), answers('provided')).score, 1);
  assert.equal(personalScore(answers('yes'), answers('incorrect'), answers('provided')).score, 0);
});

test('non-inference is overestimation when expected and agreement when unexpected', () => {
  const expected = personalScore(answers('yes'), answers('invalid'), answers('not_inferred'));
  assert.equal(expected.score, 0);
  assert.equal(expected.overestimation_count, 8);
  const unexpected = personalScore(answers('no'), answers('invalid'), answers('not_inferred'));
  assert.equal(unexpected.score, 1);
  assert.equal(unexpected.agreement_count, 8);
});

test('mixed answers use the same denominator for gap, score and both directions', () => {
  const expectations = { ...answers('yes'), alter: 'no' };
  const ratings = { ...answers('correct'), geschlecht: 'invalid', beruf: 'invalid', einkommen: 'incorrect', wohnort: 'invalid' };
  const statuses = { ...answers('provided'), geschlecht: 'not_inferred', beruf: 'refused' };
  const result = personalScore(expectations, ratings, statuses);
  assert.equal(result.evaluable_count, 6);
  assert.equal(result.excluded_count, 2);
  assert.equal(result.not_inferred_count, 1);
  assert.equal(result.refused_count, 1);
  assert.equal(result.invalid_count, 1);
  assert.equal(result.agreement_count, 3);
  assert.equal(result.score, 0.5);
  assert.equal(result.gap_rate, 0.5);
  assert.equal(result.underestimation_rate, 1 / 6);
  assert.equal(result.overestimation_rate, 2 / 6);
});

test('fully excluded answers leave the score and gap undefined rather than zero', () => {
  for (const status of ['refused', 'provided']) {
    const result = personalScore(answers('yes'), answers('invalid'), answers(status));
    assert.equal(result.score, null);
    assert.equal(result.gap_rate, null);
    assert.equal(result.evaluable_count, 0);
  }
});
