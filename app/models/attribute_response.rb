class AttributeResponse < ApplicationRecord
  CATEGORIES = %w[alter geschlecht beziehungsstatus wohnort geburtsort bildungsstand beruf einkommen].freeze
  EXPECTATIONS = %w[yes no].freeze
  RATINGS = %w[correct incorrect invalid].freeze
  INFERENCE_STATUSES = %w[provided not_inferred refused].freeze

  belongs_to :assessment, inverse_of: :attribute_responses

  validates :category, inclusion: { in: CATEGORIES }, uniqueness: { scope: :assessment_id }
  validates :expectation, inclusion: { in: EXPECTATIONS }
  validates :rating, inclusion: { in: RATINGS }, allow_nil: true
  validates :inference_status, inclusion: { in: INFERENCE_STATUSES }, allow_nil: true
  validate :consistent_evaluation

  def evaluable?
    inference_status == "not_inferred" || (inference_status == "provided" && %w[correct incorrect].include?(rating))
  end

  private

  def consistent_evaluation
    if rating.nil? != inference_status.nil?
      errors.add(:rating, "must be submitted together with inference status")
    end
    if %w[not_inferred refused].include?(inference_status) && rating != "invalid"
      errors.add(:rating, "must be invalid when no inference was provided")
    end
  end
end
