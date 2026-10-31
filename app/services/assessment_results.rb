class AssessmentResults
  def self.call
    new.call
  end

  def call
    Assessment.transaction do
      @assessments = Assessment.completed.where(instrument_version: Assessment::INSTRUMENT_VERSION)
      minimum = Rails.application.config.x.results_min_participants
      participants = @assessments.count
      result = { available: participants >= minimum, minimum_participants: minimum, instrument_version: Assessment::INSTRUMENT_VERSION }
      return result unless result[:available]

      @responses = AttributeResponse.where(assessment_id: @assessments.select(:id))
      rows = @responses.group(:category, :expectation, :inference_status, :rating).count
      categories = AttributeResponse::CATEGORIES.map do |category|
        values = rows.filter_map { |(key, expectation, status, rating), count| [ expectation, status, rating, count ] if key == category }
        summarize(values).merge(category: category)
      end
      totals = summarize(rows.map { |(_category, expectation, status, rating), count| [ expectation, status, rating, count ] })

      result.merge(
        participant_count: participants,
        overall: totals.merge(participant_means),
        categories: categories,
        models: breakdown(:model, minimum),
        age_groups: breakdown(:age_group, minimum)
      )
    end
  end

  private

  def summarize(rows)
    counts = {
      response_count: 0, evaluable_count: 0, excluded_count: 0,
      not_inferred_count: 0, refused_count: 0, invalid_count: 0,
      correct_count: 0, incorrect_count: 0, expected_count: 0,
      underestimation_count: 0, overestimation_count: 0,
      expected_correct_count: 0, expected_failure_count: 0
    }
    rows.each do |expectation, status, rating, count|
      counts[:response_count] += count
      counts[:not_inferred_count] += count if status == "not_inferred"
      counts[:refused_count] += count if status == "refused"
      counts[:invalid_count] += count if status == "provided" && rating == "invalid"
      evaluable = status == "not_inferred" || (status == "provided" && %w[correct incorrect].include?(rating))
      unless evaluable
        counts[:excluded_count] += count
        next
      end

      counts[:evaluable_count] += count
      correct = status == "provided" && rating == "correct"
      counts[:correct_count] += count if correct
      counts[:incorrect_count] += count if status == "provided" && rating == "incorrect"
      counts[:expected_count] += count if expectation == "yes"
      key = if expectation == "yes"
        correct ? :expected_correct_count : :overestimation_count
      else
        correct ? :underestimation_count : :expected_failure_count
      end
      counts[key] += count
    end
    counts[:agreement_count] = counts[:expected_correct_count] + counts[:expected_failure_count]
    counts[:gap_count] = counts[:overestimation_count] + counts[:underestimation_count]
    counts.merge(
      gap_rate: ratio(counts[:gap_count], counts[:evaluable_count]),
      underestimation_rate: ratio(counts[:underestimation_count], counts[:evaluable_count]),
      overestimation_rate: ratio(counts[:overestimation_count], counts[:evaluable_count]),
      agreement_rate: ratio(counts[:agreement_count], counts[:evaluable_count]),
      expectation_rate: ratio(counts[:expected_count], counts[:evaluable_count]),
      correct_rate: ratio(counts[:correct_count], counts[:evaluable_count]),
      coverage_rate: ratio(counts[:evaluable_count], counts[:response_count])
    )
  end

  def participant_means
    evaluable = "inference_status = 'not_inferred' OR (inference_status = 'provided' AND rating IN ('correct', 'incorrect'))"
    underestimation = "expectation = 'no' AND inference_status = 'provided' AND rating = 'correct'"
    overestimation = "expectation = 'yes' AND (inference_status = 'not_inferred' OR (inference_status = 'provided' AND rating = 'incorrect'))"
    counts = @responses.group(:assessment_id).pluck(
      Arel.sql("SUM(CASE WHEN #{evaluable} THEN 1 ELSE 0 END)"),
      Arel.sql("SUM(CASE WHEN #{underestimation} THEN 1 ELSE 0 END)"),
      Arel.sql("SUM(CASE WHEN #{overestimation} THEN 1 ELSE 0 END)")
    )
    valid = counts.select { |denominator, _under, _over| denominator.positive? }
    {
      participants_with_evaluable_answers: valid.size,
      participants_without_evaluable_answers: counts.size - valid.size,
      mean_individual_gap_rate: valid.empty? ? nil : valid.sum { |denominator, under, over| (under + over).fdiv(denominator) }.fdiv(valid.size)
    }
  end

  def breakdown(dimension, minimum)
    sizes = @assessments.group(dimension).count
    if dimension == :age_group
      sizes = publishable_age_groups(sizes, minimum)
    elsif sizes.values.any? { |size| size < minimum }
      sizes = {}
    end
    return { available: false, groups: [] } if sizes.empty?

    rows = @responses.joins(:assessment).where(assessments: { dimension => sizes.keys })
      .group(Assessment.arel_table[dimension], :expectation, :inference_status, :rating).count
    order = dimension == :model ? Assessment::MODELS : Assessment::AGE_GROUPS
    groups = order.filter_map do |label|
      next unless sizes.key?(label)

      values = rows.filter_map { |(group, expectation, status, rating), count| [ expectation, status, rating, count ] if group == label }
      summarize(values).merge(label: label, participant_count: sizes[label])
    end
    { available: true, groups: groups }
  end

  def publishable_age_groups(sizes, minimum)
    visible = sizes.select { |_label, count| count >= minimum }
    hidden_count = sizes.values.sum - visible.values.sum
    if hidden_count.positive? && hidden_count < minimum && visible.any?
      label = visible.min_by { |group, count| [ count, Assessment::AGE_GROUPS.index(group) ] }.first
      visible.delete(label)
    end
    visible
  end

  def ratio(numerator, denominator)
    numerator.fdiv(denominator) if denominator.positive?
  end
end
