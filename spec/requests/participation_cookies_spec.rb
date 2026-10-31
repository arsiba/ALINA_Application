require "rails_helper"

RSpec.describe "Participation cookies", type: :request do
  let(:assessment_id) { SecureRandom.uuid }
  let(:baseline) { { basis: { age_group: "25–34", model: "ChatGPT" }, expectations: AttributeResponse::CATEGORIES.index_with { "yes" } } }
  let(:evaluation) { { ratings: AttributeResponse::CATEGORIES.index_with { "correct" }, inference_statuses: AttributeResponse::CATEGORIES.index_with { "provided" } } }
  let(:status_key) { ParticipationCookies::STATUS_KEY }

  def submit(step, data, id: assessment_id)
    post "/form/submissions", params: { assessment_id: id, step: step, data: data }, as: :json
  end

  def status_cookie_header
    Array(response.headers["Set-Cookie"]).find { |header| header.start_with?("#{status_key}=") }
  end

  it "sets no participation cookie on a first visit and exposes only the boolean status" do
    get "/cookies", headers: { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("props").fetch("cookie_settings")).to eq("participated" => false, "duration_days" => 30)
    expect(response.cookies).not_to have_key(status_key)
    expect(response.headers["Cache-Control"]).to include("no-store")
  end

  it "sets only the literal flag after successful completion, with limited duration and access" do
    submit("baseline", baseline)
    expect(response.cookies).not_to have_key(status_key)
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:ok)
    expect(response.cookies[status_key]).to eq("1")
    header = status_cookie_header
    expect(header.downcase).to include("httponly", "samesite=lax", "path=/", "max-age=2592000")
    expect(header).not_to include(assessment_id, "score", "25–34", "ChatGPT", "domain=")
    expect(Time.httpdate(header[/expires=([^;]+)/i, 1])).to be_within(5.seconds).of(30.days.from_now)
    get "/form", headers: { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    expect(response.parsed_body.fetch("props").fetch("cookie_settings")).to include("participated" => true)
    expect(status_cookie_header).to be_nil
  end

  it "blocks new submissions in a marked browser without creating further research records" do
    submit("baseline", baseline)
    submit("evaluation", evaluation)
    expect { submit("baseline", baseline, id: SecureRandom.uuid) }.not_to change(Assessment, :count)
    expect(response).to have_http_status(:conflict)
    expect(status_cookie_header).to be_nil
  end

  it "does not let an older unfinished assessment bypass the browser participation guard" do
    other_id = SecureRandom.uuid
    submit("baseline", baseline, id: other_id)
    submit("baseline", baseline)
    submit("evaluation", evaluation)
    submit("evaluation", evaluation, id: other_id)
    expect(response).to have_http_status(:conflict)
    expect(Assessment.find_by!(public_id: other_id).completed_at).to be_nil
  end

  it "allows identical retries of saved submissions without extending the cookie lifetime" do
    submit("baseline", baseline)
    submit("evaluation", evaluation)
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:ok)
    expect(status_cookie_header).to be_nil
    submit("baseline", baseline)
    expect(response).to have_http_status(:ok)
    expect(Assessment.count).to eq(1)
    expect(status_cookie_header).to be_nil
  end

  it "sets no marker for incomplete, failed or rejected submissions" do
    submit("evaluation", evaluation)
    expect(response).to have_http_status(:not_found)
    expect(response.cookies).not_to have_key(status_key)
    submit("baseline", baseline)
    submit("evaluation", evaluation.merge(ratings: {}))
    expect(response).to have_http_status(422)
    expect(response.cookies).not_to have_key(status_key)
  end

  it "adds Secure on HTTPS and retains HttpOnly" do
    https!
    submit("baseline", baseline)
    submit("evaluation", evaluation)
    expect(status_cookie_header.downcase).to include("secure", "httponly", "samesite=lax")
  end
end
