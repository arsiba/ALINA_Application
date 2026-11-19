import assert from 'node:assert/strict';

export function checkEqual(actual, expected, label) {
  console.log('EVALUATION_OBSERVATION ' + JSON.stringify({ label, expected, actual }));
  assert.deepEqual(actual, expected);
}
