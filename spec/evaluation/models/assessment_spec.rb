require "rails_helper"
require_relative "../support/observations"

RSpec.describe Assessment, type: :model do
  def build_assessment
    described_class.new(public_id: SecureRandom.uuid, age_group: "25–34", model: "ChatGPT", instrument_version: described_class::INSTRUMENT_VERSION).tap do |assessment|
      AttributeResponse::CATEGORIES.each do |category|
        assessment.attribute_responses.build(category: category, expectation: "yes")
      end
    end
  end

  it "[MOD-01] Acht Erwartungen speichern und offene Antworten unterscheiden" do
    assessment = build_assessment
    assessment.save!
    expect(assessment.reload.attribute_responses.count).to eq(8)
    expect(assessment.attribute_responses.map(&:inference_status)).to eq([ nil ] * 8)
    expect(assessment.evaluation).to be_nil
    expect(described_class.completed).to be_empty
  end

  it "[MOD-02] Vollständigen und eindeutigen Kategoriensatz erzwingen" do
    assessment = build_assessment
    assessment.completed_at = Time.current
    expect(assessment).not_to be_valid
    assessment.completed_at = nil
    assessment.attribute_responses.last.category = "alter"
    expect(assessment).not_to be_valid
  end

  it "[MOD-03] Gemischten Einzelfall gegen feste Sollwerte prüfen" do
    assessment = build_assessment
    statuses = %w[not_inferred not_inferred provided provided provided provided refused provided]
    ratings = %w[invalid invalid correct incorrect correct incorrect invalid invalid]
    expectations = %w[yes no no yes yes no yes yes]
    assessment.attribute_responses.each_with_index do |answer, index|
      answer.assign_attributes(inference_status: statuses[index], rating: ratings[index], expectation: expectations[index])
    end
    assessment.completed_at = Time.current
    assessment.save!
    expected = { evaluable_count: 6, excluded_count: 2, not_inferred_count: 2, refused_count: 1, invalid_count: 1,
      underestimation_count: 1, overestimation_count: 2, gap_rate: 0.5,
      underestimation_rate: 1.fdiv(6), overestimation_rate: 2.fdiv(6) }
    actual = assessment.reload.evaluation
    compare_metrics("Gemischter Einzelfall", expected: expected, actual: actual)
    expect(actual).to eq(expected)
  end

  it "[MOD-04] Bei ausschließlich ausgeschlossenen Antworten keine Quote berechnen" do
    assessment = build_assessment
    assessment.attribute_responses.each { |answer| answer.assign_attributes(inference_status: "refused", rating: "invalid") }
    assessment.completed_at = Time.current
    assessment.save!
    compare_metrics("Individuelle Kennzahlen", actual: assessment.evaluation, expected: { evaluable_count: 0, excluded_count: 8, gap_rate: nil, underestimation_rate: nil, overestimation_rate: nil })
  end

  it "[MOD-05] Datenbank schützt Eindeutigkeit und konsistente Bewertungen" do
    assessment = build_assessment
    assessment.save!
    answer = assessment.attribute_responses.first
    expect { answer.update_columns(category: assessment.attribute_responses.last.category) }.to raise_error(ActiveRecord::RecordNotUnique)
    expect { answer.update_columns(assessment_id: -1) }.to raise_error(ActiveRecord::InvalidForeignKey)
    expect { answer.update_columns(inference_status: "not_inferred", rating: "correct") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { answer.update_columns(inference_status: "provided", rating: nil) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "[MOD-06] Beim Löschen keine verwaisten Kategorieantworten hinterlassen" do
    assessment = build_assessment
    assessment.save!
    expect { assessment.destroy! }.to change(AttributeResponse, :count).by(-8)
  end

  it "[MOD-07] Alle gültigen Erwartungs-, Status- und Bewertungskombinationen gegen Referenzwerte prüfen" do
    cases = JSON.parse(File.read(Rails.root.join("spec/evaluation/fixtures/measurement_cases.json")))
    combinations = %w[yes no].product([
      %w[provided correct], %w[provided incorrect], %w[provided invalid],
      %w[not_inferred invalid], %w[refused invalid]
    ]).map(&:flatten)
    actual_combinations = cases.map { |reference| reference.values_at("expectation", "inference_status", "rating") }
    compare_observation("Vollständige gültige Falltabelle", expected: combinations.sort, actual: actual_combinations.sort)
    cases.each do |reference|
      assessment = build_assessment
      assessment.attribute_responses.each do |answer|
        answer.assign_attributes(reference.slice("expectation", "inference_status", "rating"))
      end
      assessment.completed_at = Time.current
      assessment.save!
      expected = reference.fetch("expected").except("score", "agreement_count")
      compare_metrics(reference.fetch("id"), expected: expected, actual: assessment.reload.evaluation.stringify_keys)
    end
  end
end
