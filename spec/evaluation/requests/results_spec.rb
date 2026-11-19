require "rails_helper"

RSpec.describe "Results", type: :request do
  it "[OUT-01] Gesperrte Ergebnisse auch im HTTP-Payload schützen" do
    allow(Rails.application.config.x).to receive(:results_min_participants).and_return(37)
    get "/result", headers: { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("props").fetch("results")).to eq(
      "available" => false, "minimum_participants" => 37, "instrument_version" => Assessment::INSTRUMENT_VERSION
    )
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "[OUT-02] Freigabeschwelle nicht durch URL-Parameter umgehen lassen" do
    get "/result", params: { minimum_participants: 0, assessment_id: SecureRandom.uuid, model: "ChatGPT" }, headers: { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    expect(response.parsed_body.fetch("props").fetch("results").keys).to contain_exactly("available", "minimum_participants", "instrument_version")
  end
  it "[OUT-03] Kleine und ergänzende Altersgruppen aus Serverantwort entfernen" do
    allow(Rails.application.config.x).to receive(:results_min_participants).and_return(2)
    { "18–24" => 1, "25–34" => 2, "35–44" => 3 }.each do |age_group, count|
      count.times do
        Assessment.create!(public_id: SecureRandom.uuid, age_group: age_group, model: "ChatGPT", instrument_version: Assessment::INSTRUMENT_VERSION, completed_at: Time.current) do |assessment|
          AttributeResponse::CATEGORIES.each do |category|
            assessment.attribute_responses.build(category: category, expectation: "yes", inference_status: "provided", rating: "correct")
          end
        end
      end
    end

    get "/result", headers: { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    expect(response).to have_http_status(:ok)
    results = response.parsed_body.fetch("props").fetch("results")
    expect(results.fetch("participant_count")).to eq(6)
    expect(results.fetch("age_groups").fetch("groups").map { |group| group.fetch("label") }).to eq([ "35–44" ])
    expect(results.to_json).not_to include("18–24", "25–34", "public_id", "assessment_id")
  end
end
