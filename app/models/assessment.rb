class Assessment < ApplicationRecord
  INSTRUMENT_VERSION = "1".freeze
  AGE_GROUPS = [ "Unter 18", "18–24", "25–34", "35–44", "45–54", "55–64", "65 oder älter" ].freeze
  MODELS = %w[ChatGPT Claude Gemini Copilot Anderes].freeze

  has_many :attribute_responses, dependent: :destroy, inverse_of: :assessment

  validates :public_id, format: { with: /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/ }, uniqueness: true
  validates :age_group, inclusion: { in: AGE_GROUPS }
  validates :model, inclusion: { in: MODELS }
  validates :instrument_version, presence: true
  validate :complete_response_set

  scope :completed, -> { where.not(completed_at: nil) }

  def evaluation
    return unless completed_at?

    responses = attribute_responses.to_a
    evaluable = responses.select(&:evaluable?)
    underestimated = evaluable.count { |answer| answer.expectation == "no" && answer.rating == "correct" }
    overestimated = evaluable.count { |answer| answer.expectation == "yes" && answer.rating != "correct" }
    denominator = evaluable.size

    {
      evaluable_count: denominator,
      excluded_count: responses.size - denominator,
      not_inferred_count: responses.count { |answer| answer.inference_status == "not_inferred" },
      refused_count: responses.count { |answer| answer.inference_status == "refused" },
      invalid_count: responses.count { |answer| answer.inference_status == "provided" && answer.rating == "invalid" },
      underestimation_count: underestimated,
      overestimation_count: overestimated,
      gap_rate: denominator.positive? ? (underestimated + overestimated).fdiv(denominator) : nil,
      underestimation_rate: denominator.positive? ? underestimated.fdiv(denominator) : nil,
      overestimation_rate: denominator.positive? ? overestimated.fdiv(denominator) : nil
    }
  end

  private

  def complete_response_set
    responses = attribute_responses.to_a
    unless responses.map(&:category).sort == AttributeResponse::CATEGORIES.sort
      errors.add(:attribute_responses, "must contain each category exactly once")
    end
    if completed_at? && responses.any? { |answer| answer.inference_status.nil? || answer.rating.nil? }
      errors.add(:attribute_responses, "must be evaluated before completion")
    end
  end
end
