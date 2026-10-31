require "rails_helper"

RSpec.describe AssessmentResults do
  before { allow(Rails.application.config.x).to receive(:results_min_participants).and_return(2) }

  def assessment(model: "ChatGPT", age_group: "25–34", version: Assessment::INSTRUMENT_VERSION, completed: true, answers: {})
    Assessment.create!(public_id: SecureRandom.uuid, age_group: age_group, model: model, instrument_version: version, completed_at: completed ? Time.current : nil) do |record|
      AttributeResponse::CATEGORIES.each do |category|
        record.attribute_responses.build(category: category, expectation: "yes", inference_status: completed ? "provided" : nil, rating: completed ? "correct" : nil, **answers.fetch(category, {}))
      end
    end
  end

  it "returns no counts or breakdowns below the configured completion threshold" do
    assessment
    assessment(completed: false)
    assessment(version: "old")
    expect(described_class.call).to eq(available: false, minimum_participants: 2, instrument_version: Assessment::INSTRUMENT_VERSION)
  end

  it "opens at the exact threshold and excludes incomplete and other instrument versions" do
    2.times { assessment }
    assessment(completed: false)
    assessment(version: "old")
    results = described_class.call
    expect(results).to include(available: true, participant_count: 2)
    expect(results[:overall]).to include(response_count: 16, evaluable_count: 16, gap_rate: 0.0, correct_rate: 1.0)
    expect(results[:categories].size).to eq(8)
    expect(results[:categories].map { |row| row[:response_count] }).to eq([ 2 ] * 8)
  end

  it "preserves nulls as evaluable failures, distinguishes exclusions, and separates both gap directions" do
    answers = {
      "alter" => { inference_status: "not_inferred", rating: "invalid" },
      "geschlecht" => { inference_status: "refused", rating: "invalid" },
      "beruf" => { inference_status: "provided", rating: "invalid" },
      "einkommen" => { expectation: "no" },
      "wohnort" => { rating: "incorrect" },
      "geburtsort" => { expectation: "no", inference_status: "not_inferred", rating: "invalid" }
    }
    records = 2.times.map { assessment(answers: answers) }
    results = described_class.call
    expect(results[:overall]).to include(
      response_count: 16, evaluable_count: 12, excluded_count: 4,
      not_inferred_count: 4, refused_count: 2, invalid_count: 2,
      underestimation_count: 2, overestimation_count: 4, agreement_count: 6,
      gap_rate: 0.5, coverage_rate: 0.75, correct_rate: 0.5,
      mean_individual_gap_rate: 0.5
    )
    expect(results[:overall][:gap_rate]).to eq(records.first.evaluation[:gap_rate])
    expect(results[:categories].find { |row| row[:category] == "geschlecht" }).to include(gap_rate: nil, evaluable_count: 0, excluded_count: 2)
    expect(results[:categories].find { |row| row[:category] == "alter" }).to include(overestimation_rate: 1.0, correct_rate: 0.0)
  end

  it "distinguishes pooled rates from equally weighted individual rates" do
    assessment(answers: AttributeResponse::CATEGORIES.index_with { { rating: "incorrect" } })
    answers = AttributeResponse::CATEGORIES.index_with { { inference_status: "refused", rating: "invalid" } }
    answers["alter"] = { inference_status: "provided", rating: "correct" }
    assessment(answers: answers)
    expect(described_class.call[:overall]).to include(gap_rate: 8.fdiv(9), mean_individual_gap_rate: 0.5)
  end

  it "keeps zero-denominator rates undefined and reports all excluded participants" do
    answers = AttributeResponse::CATEGORIES.index_with { { inference_status: "refused", rating: "invalid" } }
    2.times { assessment(answers: answers) }
    expect(described_class.call[:overall]).to include(gap_rate: nil, correct_rate: nil, coverage_rate: 0.0, mean_individual_gap_rate: nil, participants_without_evaluable_answers: 2)
  end

  it "suppresses an entire partition if a small group could be inferred by subtraction" do
    2.times { assessment }
    assessment(model: "Claude", age_group: "18–24")
    results = described_class.call
    expect(results[:models]).to eq(available: false, groups: [])
    expect(results[:age_groups]).to eq(available: false, groups: [])
    expect(results.to_json).not_to include("Claude", "18–24")
  end

  it "releases disjoint groups only when every represented group reaches the threshold" do
    2.times { assessment }
    2.times { assessment(model: "Claude", age_group: "18–24", answers: { "alter" => { rating: "incorrect" } }) }
    results = described_class.call
    expect(results[:models][:available]).to be(true)
    expect(results[:models][:groups].map { |group| group[:participant_count] }).to eq([ 2, 2 ])
    expect(results[:models][:groups].find { |group| group[:label] == "Claude" }).to include(gap_rate: 1.fdiv(8))
    expect(results[:age_groups][:groups].map { |group| group[:label] }).to eq([ "18–24", "25–34" ])
    expect(results.to_json).not_to include("public_id", "assessment_id", "completed_at")
  end
  it "hides small age groups and a complementary group when the remainder is below the threshold" do
    2.times { assessment(age_group: "25–34") }
    3.times { assessment(age_group: "35–44") }
    assessment(age_group: "18–24")
    groups = described_class.call[:age_groups]
    expect(groups[:available]).to be(true)
    expect(groups[:groups].map { |group| group[:label] }).to eq([ "35–44" ])
    expect(groups[:groups].first[:participant_count]).to eq(3)
    expect(groups.to_json).not_to include("18–24", "25–34")
  end

  it "keeps large age groups when the combined hidden remainder already reaches the threshold" do
    2.times { assessment(age_group: "25–34") }
    assessment(age_group: "18–24")
    assessment(age_group: "55–64")
    groups = described_class.call[:age_groups]
    expect(groups[:groups].map { |group| group[:label] }).to eq([ "25–34" ])
    expect(groups.to_json).not_to include("18–24", "55–64")
  end

  it "counts only completed assessments of the current version toward each age group threshold" do
    2.times { assessment(age_group: "25–34") }
    assessment(age_group: "18–24")
    assessment(age_group: "18–24", completed: false)
    assessment(age_group: "18–24", version: "old")
    expect(described_class.call[:age_groups]).to eq(available: false, groups: [])
  end
end
