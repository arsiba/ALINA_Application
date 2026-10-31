require "rails_helper"

RSpec.describe Assessment, type: :model do
  def build_assessment
    described_class.new(public_id: SecureRandom.uuid, age_group: "25–34", model: "ChatGPT", instrument_version: described_class::INSTRUMENT_VERSION).tap do |assessment|
      AttributeResponse::CATEGORIES.each do |category|
        assessment.attribute_responses.build(category: category, expectation: "yes")
      end
    end
  end

  it "persists all eight expectations without confusing pending answers with imported nulls" do
    assessment = build_assessment
    assessment.save!
    expect(assessment.reload.attribute_responses.count).to eq(8)
    expect(assessment.attribute_responses.map(&:inference_status)).to eq([ nil ] * 8)
    expect(assessment.evaluation).to be_nil
    expect(described_class.completed).to be_empty
  end

  it "requires exactly one answer per category and a complete evaluation before completion" do
    assessment = build_assessment
    assessment.completed_at = Time.current
    expect(assessment).not_to be_valid
    assessment.completed_at = nil
    assessment.attribute_responses.last.category = "alter"
    expect(assessment).not_to be_valid
  end

  it "counts non-inferences as overestimation and separates exclusions and both gap directions" do
    assessment = build_assessment
    statuses = %w[not_inferred not_inferred provided provided provided provided refused provided]
    ratings = %w[invalid invalid correct incorrect correct incorrect invalid invalid]
    expectations = %w[yes no no yes yes no yes yes]
    assessment.attribute_responses.each_with_index do |answer, index|
      answer.assign_attributes(inference_status: statuses[index], rating: ratings[index], expectation: expectations[index])
    end
    assessment.completed_at = Time.current
    assessment.save!
    expect(assessment.reload.evaluation).to eq(
      evaluable_count: 6, excluded_count: 2, not_inferred_count: 2, refused_count: 1, invalid_count: 1,
      underestimation_count: 1, overestimation_count: 2, gap_rate: 0.5,
      underestimation_rate: 1.fdiv(6), overestimation_rate: 2.fdiv(6)
    )
  end

  it "leaves rates undefined when every answer is excluded" do
    assessment = build_assessment
    assessment.attribute_responses.each { |answer| answer.assign_attributes(inference_status: "refused", rating: "invalid") }
    assessment.completed_at = Time.current
    assessment.save!
    expect(assessment.evaluation).to include(evaluable_count: 0, excluded_count: 8, gap_rate: nil, underestimation_rate: nil, overestimation_rate: nil)
  end

  it "enforces unique categories, foreign keys and evaluation consistency in the database" do
    assessment = build_assessment
    assessment.save!
    answer = assessment.attribute_responses.first
    expect { answer.update_columns(category: assessment.attribute_responses.last.category) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { answer.update_columns(assessment_id: -1) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { answer.update_columns(inference_status: "not_inferred", rating: "correct") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { answer.update_columns(inference_status: "provided", rating: nil) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "deletes associated responses with the assessment" do
    assessment = build_assessment
    assessment.save!
    expect { assessment.destroy! }.to change(AttributeResponse, :count).by(-8)
  end
end
