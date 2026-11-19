require "rails_helper"

RSpec.describe "Form submissions", type: :request do
  let(:assessment_id) { "d8b1af2a-44d6-4e94-a146-06f9a9d2d1b0" }
  let(:expectations) { AttributeResponse::CATEGORIES.index_with { "yes" } }
  let(:ratings) { AttributeResponse::CATEGORIES.index_with { "correct" } }
  let(:statuses) { AttributeResponse::CATEGORIES.index_with { "provided" } }
  let(:baseline) { { basis: { age_group: "25–34", model: "ChatGPT" }, expectations: expectations } }
  let(:evaluation) { { ratings: ratings, inference_statuses: statuses } }

  def submit(step, data, id: assessment_id)
    post "/form/submissions", params: { assessment_id: id, step: step, data: data }, as: :json
  end

  it "[REQ-01] Basisdaten und Erwartungen gemeinsam persistieren" do
    expect { submit("baseline", baseline) }.to change(Assessment, :count).by(1).and change(AttributeResponse, :count).by(8)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("accepted" => true, "step" => "baseline")
    assessment = Assessment.find_by!(public_id: assessment_id)
    expect(assessment).to have_attributes(age_group: "25–34", model: "ChatGPT", instrument_version: Assessment::INSTRUMENT_VERSION, completed_at: nil)
    expect(assessment.attribute_responses.pluck(:expectation)).to eq([ "yes" ] * 8)
  end

  it "[REQ-02] Nicht-Ableitung, Verweigerung und Enthaltung getrennt speichern" do
    submit("baseline", baseline)
    ratings.merge!("alter" => "invalid", "geschlecht" => "invalid", "beruf" => "invalid")
    statuses.merge!("alter" => "not_inferred", "geschlecht" => "refused")
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:ok)
    assessment = Assessment.completed.find_by!(public_id: assessment_id)
    expect(assessment.evaluation).to include(not_inferred_count: 1, refused_count: 1, invalid_count: 1, overestimation_count: 1, evaluable_count: 6)
  end

  it "[REQ-03] Identische Wiederholungen idempotent verarbeiten" do
    submit("baseline", baseline)
    first = Assessment.find_by!(public_id: assessment_id)
    expect { submit("baseline", baseline, id: assessment_id.upcase) }.not_to change(AttributeResponse, :count)
    expect(response).to have_http_status(:ok)
    submit("evaluation", evaluation)
    completed_at = first.reload.completed_at
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:ok)
    expect(first.reload.completed_at).to eq(completed_at)
    submit("baseline", baseline)
    expect(response).to have_http_status(:ok)
    expect(Assessment.count).to eq(1)
  end

  it "[REQ-04] Bereits gespeicherte Antworten vor Überschreiben schützen" do
    submit("baseline", baseline)
    changed = baseline.deep_dup
    changed[:expectations]["alter"] = "no"
    submit("baseline", changed)
    expect(response).to have_http_status(:conflict)
    submit("evaluation", evaluation)
    ratings["alter"] = "incorrect"
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:conflict)
    expect(AttributeResponse.find_by!(category: "alter").rating).to eq("correct")
  end

  it "[REQ-05] Bewertung ohne Basis ablehnen" do
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:not_found)
    expect(Assessment.count).to eq(0)
    expect(AttributeResponse.count).to eq(0)
  end

  it "[REQ-06] Unvollständige und unbekannte Kategorien atomar ablehnen" do
    expectations.delete("alter")
    submit("baseline", baseline)
    expect(response).to have_http_status(422)
    expectations["unknown"] = "yes"
    submit("baseline", baseline)
    expect(response).to have_http_status(422)
    expect(Assessment.count).to eq(0)
    expect(AttributeResponse.count).to eq(0)
  end

  it "[REQ-07] Unzulässiges LLM in Basisdaten ablehnen" do
    baseline[:basis][:model] = "unexpected"
    submit("baseline", baseline)
    expect(response).to have_http_status(422)
  end

  it "[REQ-08] Ungültige Bewertungsstrukturen ohne Änderung ablehnen" do
    submit("baseline", baseline)
    [
      { ratings: ratings },
      evaluation.merge(inference_statuses: statuses.merge("alter" => nil)),
      evaluation.merge(inference_statuses: statuses.merge("alter" => "unknown")),
      evaluation.merge(ratings: ratings.merge("alter" => "unexpected")),
      evaluation.merge(inference_statuses: statuses.merge("alter" => "not_inferred")),
      evaluation.merge(inference_statuses: statuses.merge("alter" => "refused"))
    ].each do |data|
      submit("evaluation", data)
      expect(response).to have_http_status(422)
      expect(AttributeResponse.where.not(rating: nil)).to be_empty
      expect(Assessment.completed).to be_empty
    end
  end

  it "[REQ-09] Bei Speicherfehler den gesamten Bewertungsabschnitt zurückrollen" do
    submit("baseline", baseline)
    allow_any_instance_of(AttributeResponse).to receive(:update!).and_wrap_original do |method, *args|
      raise ActiveRecord::RecordInvalid.new(method.receiver) if method.receiver.category == "einkommen"
      method.call(*args)
    end
    submit("evaluation", evaluation)
    expect(response).to have_http_status(422)
    expect(AttributeResponse.where.not(rating: nil)).to be_empty
    expect(Assessment.completed).to be_empty
  end

  it "[REQ-10] Zusätzliche konkrete Inferenzdaten serverseitig ablehnen" do
    submit("baseline", baseline.merge(inference: { alter: "LOCAL_SECRET" }))
    expect(response).to have_http_status(422)
    submit("baseline", baseline)
    submit("evaluation", evaluation.merge(inference: { alter: "LOCAL_SECRET" }))
    expect(response).to have_http_status(422)
  end

  it "[REQ-11] Parameterfilter für sensible Requestdaten prüfen" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter("data" => { "inference" => "LOCAL_SECRET" }, "assessment_id" => assessment_id)
    expect(filtered.values).to eq([ "[FILTERED]", "[FILTERED]" ])
  end

  it "[REQ-12] Ungültige Befragungskennungen zurückweisen" do
    [ "invalid", nil, [], {} ].each do |id|
      submit("baseline", baseline, id: id)
      expect(response).to have_http_status(422)
    end
  end

  it "[REQ-13] Unbekannte Schritte und falsche Datenstrukturen zurückweisen" do
    [ [ "unknown", baseline ], [ "baseline", "invalid" ], [ "evaluation", { ratings: [] } ], [ "baseline", nil ] ].each do |step, data|
      submit(step, data)
      expect(response).to have_http_status(422)
    end
  end

  it "[REQ-14] Tatsächliche Rails-Requestlogs enthalten keine gesendeten Inferenzmarker" do
    buffer = StringIO.new
    logger = ActiveSupport::Logger.new(buffer)
    Rails.logger.broadcast_to(logger)
    begin
      submit("baseline", baseline.merge(inference: { alter: "EVAL_LOG_SECRET_9384" }))
      expect(response).to have_http_status(422)
      submit("baseline", baseline)
      expect(response).to have_http_status(:ok)
      expect(buffer.string).to include("FormSubmissionsController", "[FILTERED]")
      expect(buffer.string).not_to include("EVAL_LOG_SECRET_9384")
      parameter_lines = buffer.string.lines.grep(/Parameters:/).join
      expect(parameter_lines).to include("[FILTERED]")
      expect(parameter_lines).not_to include("EVAL_LOG_SECRET_9384", assessment_id)
      expect(Assessment.all.map(&:attributes).to_json + AttributeResponse.all.map(&:attributes).to_json).not_to include("EVAL_LOG_SECRET_9384")
    ensure
      Rails.logger.stop_broadcasting_to(logger)
    end
  end
end
