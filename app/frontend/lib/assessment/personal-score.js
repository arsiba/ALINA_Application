import { attributes } from './attributes.js';

export function personalScore(expectations, ratings, statuses) {
  let evaluable = 0;
  let underestimated = 0;
  let overestimated = 0;
  let notInferred = 0;
  let refused = 0;
  let invalid = 0;

  for (const { id } of attributes) {
    const status = statuses[id];
    const rating = ratings[id];
    if (status === 'not_inferred') notInferred += 1;
    if (status === 'refused') refused += 1;
    if (status === 'provided' && rating === 'invalid') invalid += 1;
    if (status !== 'not_inferred' && !(status === 'provided' && ['correct', 'incorrect'].includes(rating))) continue;

    evaluable += 1;
    const correct = status === 'provided' && rating === 'correct';
    if (expectations[id] === 'no' && correct) underestimated += 1;
    if (expectations[id] === 'yes' && !correct) overestimated += 1;
  }

  const gap = underestimated + overestimated;
  const agreement = evaluable - gap;
  const rate = (count) => evaluable > 0 ? count / evaluable : null;
  return {
    evaluable_count: evaluable,
    excluded_count: attributes.length - evaluable,
    not_inferred_count: notInferred,
    refused_count: refused,
    invalid_count: invalid,
    agreement_count: agreement,
    score: rate(agreement),
    gap_count: gap,
    gap_rate: rate(gap),
    underestimation_count: underestimated,
    underestimation_rate: rate(underestimated),
    overestimation_count: overestimated,
    overestimation_rate: rate(overestimated),
  };
}
