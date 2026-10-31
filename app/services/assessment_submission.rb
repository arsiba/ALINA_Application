class AssessmentSubmission
  class Conflict < StandardError; end

  def self.baseline(public_id:, data:)
    assessment = Assessment.find_by(public_id: public_id)
    return verify_baseline(assessment, data) if assessment

    Assessment.transaction do
      assessment = Assessment.new(
        public_id: public_id,
        age_group: data[:basis][:age_group],
        model: data[:basis][:model],
        instrument_version: Assessment::INSTRUMENT_VERSION
      )
      data[:expectations].each do |category, expectation|
        assessment.attribute_responses.build(category: category, expectation: expectation)
      end
      assessment.save!
      assessment
    end
  rescue ActiveRecord::RecordNotUnique
    verify_baseline(Assessment.find_by!(public_id: public_id), data)
  end

  def self.evaluation(public_id:, data:)
    assessment = Assessment.find_by!(public_id: public_id)
    assessment.with_lock do
      responses = assessment.attribute_responses.reload
      if assessment.completed_at?
        matches = responses.all? do |answer|
          answer.rating == data[:ratings][answer.category] && answer.inference_status == data[:inference_statuses][answer.category]
        end
        raise Conflict unless matches
      else
        responses.each do |answer|
          answer.update!(rating: data[:ratings][answer.category], inference_status: data[:inference_statuses][answer.category])
        end
        assessment.update!(completed_at: Time.current)
      end
    end
    assessment
  end

  def self.verify_baseline(assessment, data)
    matches = assessment.age_group == data[:basis][:age_group] && assessment.model == data[:basis][:model] &&
      assessment.attribute_responses.all? { |answer| answer.expectation == data[:expectations][answer.category] }
    raise Conflict unless matches

    assessment
  end
  private_class_method :verify_baseline
end
