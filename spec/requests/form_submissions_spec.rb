require "rails_helper"

RSpec.describe "Form submissions", type: :request do
  let(:assessment_id) { "d8b1af2a-44d6-4e94-a146-06f9a9d2d1b0" }
  let(:expectations) { FormSubmissionsController::ATTRIBUTES.index_with { "yes" } }
  let(:ratings) { FormSubmissionsController::ATTRIBUTES.index_with { "correct" } }
  let(:baseline) { { basis: { age_group: "25–34", model: "ChatGPT" }, expectations: expectations } }

  def submit(step, data, id: assessment_id)
    post "/form/submissions", params: { assessment_id: id, step: step, data: data }, as: :json
  end

  it "accepts the bundled basis and expectations" do
    submit("baseline", baseline)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("accepted" => true, "step" => "baseline")
  end

  it "accepts ratings, including abstentions" do
    ratings["alter"] = "invalid"
    submit("evaluation", { ratings: ratings })
    expect(response).to have_http_status(:ok)
  end

  it "rejects incomplete expectations" do
    expectations.delete("alter")
    submit("baseline", baseline)
    expect(response).to have_http_status(422)
  end

  it "rejects invalid basis values" do
    baseline[:basis][:model] = "unexpected"
    submit("baseline", baseline)
    expect(response).to have_http_status(422)
  end

  it "rejects invalid ratings" do
    ratings["alter"] = "unexpected"
    submit("evaluation", { ratings: ratings })
    expect(response).to have_http_status(422)
  end

  it "rejects raw LLM answers in the transmitted data" do
    submit("evaluation", { ratings: ratings, inference: { alter: "34" } })
    expect(response).to have_http_status(422)
  end

  it "rejects an invalid assessment identifier" do
    submit("baseline", baseline, id: "invalid")
    expect(response).to have_http_status(422)
  end

  it "rejects unknown steps and invalid data structures" do
    [ [ "unknown", baseline ], [ "baseline", "invalid" ], [ "evaluation", { ratings: [] } ] ].each do |step, data|
      submit(step, data)
      expect(response).to have_http_status(422)
    end
  end
end
