require "rails_helper"
require_relative "../support/browser"

RSpec.describe "Assessment workflow", type: :feature do
  before do
    Capybara.current_driver = :assessment_chrome
    visit "/form"
    expect(page).to have_text("Bevor du beginnst")
    page.execute_script <<~JS
      window.submissions = [];
      const originalFetch = window.fetch.bind(window);
      window.fetch = (url, options) => {
        window.submissions.push(JSON.parse(options.body));
        if (window.deliveryMode === 'error') return Promise.resolve(new Response('{}', {status: 422}));
        if (window.deliveryMode === 'pending') {
          return new Promise((resolve, reject) => {
            options.signal.addEventListener('abort', () => reject(new DOMException('Aborted', 'AbortError')));
          });
        }
        return originalFetch(url, options);
      };
    JS
  end

  after { Capybara.use_default_driver }

  def answer_questions(value)
    AttributeResponse::CATEGORIES.each_with_index do |_attribute, index|
      expect(page).to have_css("fieldset", count: 1)
      find("input[value='#{value}']").click
      click_button(index == 7 ? "Abschnitt prüfen" : "Weiter")
    end
  end

  def review_baseline
    click_button "Weiter zu den Basisdaten"
    select "25–34", from: "basis-age"
    select "ChatGPT", from: "basis-model"
    click_button "Weiter"
    expect(page.evaluate_script("window.submissions")).to eq([])
    answer_questions("yes")
    expect(page).to have_button("Jetzt senden")
  end

  def send_baseline
    review_baseline
    click_button "Jetzt senden"
    expect(page).to have_field("inference-response")
  end

  it "shows the disclaimer before basis data and allows returning without sending" do
    expect(page).to have_text("Welche Daten werden übertragen?")
    expect(page).not_to have_field("basis-age")
    click_button "Weiter zu den Basisdaten"
    expect(page).to have_field("basis-age")
    click_button "Zurück"
    expect(page).to have_text("Du entscheidest selbst")
    expect(page.evaluate_script("window.submissions")).to eq([])
  end

  def check_responsive_layout
    [ 320, 375, 640, 768, 1280 ].each do |width|
      page.driver.browser.manage.window.resize_to(width, 900)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), "Horizontal overflow at #{width}px"
      page.all("main button").each do |button|
        expect(button.rect.height).to be >= 44
      end
    end
  end

  it "fits narrow mobile screens and larger breakpoints throughout the workflow" do
    check_responsive_layout
    page.driver.browser.manage.window.resize_to(375, 900)
    page.save_screenshot("/tmp/alina-disclaimer-mobile.png")
    click_button "Weiter zu den Basisdaten"
    check_responsive_layout
    select "25–34", from: "basis-age"
    select "ChatGPT", from: "basis-model"
    click_button "Weiter"
    check_responsive_layout
    page.driver.browser.manage.window.resize_to(375, 900)
    page.save_screenshot("/tmp/alina-expectation-mobile.png")
    answer_questions("yes")
    check_responsive_layout
    click_button "Jetzt senden"
    expect(page).to have_field("inference-response")
    check_responsive_layout
    inference = AttributeResponse::CATEGORIES.index_with { "32–34 Jahre" }
    fill_in "inference-response", with: inference.to_json
    click_button "Weiter"
    check_responsive_layout
    page.driver.browser.manage.window.resize_to(375, 900)
    page.save_screenshot("/tmp/alina-validation-mobile.png")
    page.driver.browser.manage.window.resize_to(1280, 900)
    page.save_screenshot("/tmp/alina-validation-desktop.png")
  end

  it "asks one question at a time and preserves previous answers when going back" do
    click_button "Weiter zu den Basisdaten"
    select "25–34", from: "basis-age"
    select "ChatGPT", from: "basis-model"
    click_button "Weiter"
    expect(page).to have_css("h1", text: "Kann dein LLM dein Alter ableiten?")
    expect(page).to have_css("fieldset", count: 1)
    click_button "Weiter"
    expect(page).to have_css("h1", text: "Kann dein LLM dein Alter ableiten?")
    find('input[value="yes"]').click
    click_button "Weiter"
    expect(page).to have_css("h1", text: "Kann dein LLM dein Geschlecht ableiten?")
    click_button "Zurück"
    expect(page).to have_checked_field("Ja, das erwarte ich")
    expect(page.evaluate_script("window.submissions")).to eq([])
  end

  it "sends once per major step and excludes local LLM answers from every payload" do
    review_baseline
    expect(page.evaluate_script("window.submissions")).to eq([])
    click_button "Bearbeiten"
    click_button "Weiter zu den Basisdaten"
    expect(page).to have_select("basis-model", selected: "ChatGPT")
    click_button "Weiter"
    answer_questions("yes")
    click_button "Jetzt senden"
    expect(page).to have_field("inference-response")
    first = page.evaluate_script("window.submissions[0]")
    expect(first["data"].keys).to contain_exactly("basis", "expectations")
    expect(first["data"]["expectations"].values).to eq([ "yes" ] * 8)

    inference = AttributeResponse::CATEGORIES.index_with { "LOCAL_SECRET" }
    fill_in "inference-response", with: inference.to_json
    click_button "Weiter"
    expect(page).to have_text("LOCAL_SECRET")
    expect(page.evaluate_script("window.submissions.length")).to eq(1)
    answer_questions("correct")
    expect(page).not_to have_text("LOCAL_SECRET")
    click_button "Jetzt senden"
    expect(page).to have_text("Alle 2 Abschnitte gesendet.")
    submissions = page.evaluate_script("window.submissions")
    expect(submissions.length).to eq(2)
    expect(submissions[1]["assessment_id"]).to eq(first["assessment_id"])
    expect(submissions[1]["data"].keys).to contain_exactly("ratings", "inference_statuses")
    expect(submissions[1]["data"]["inference_statuses"].values).to eq([ "provided" ] * 8)
    expect(submissions.to_json).not_to include("LOCAL_SECRET", "response", "attributes")
    expect(page).to have_css("details", count: 2)
  end

  it "transmits null and safety refusal statuses without exposing inference values" do
    allow(Rails.application.config.x).to receive(:results_min_participants).and_return(1)
    send_baseline
    inference = AttributeResponse::CATEGORIES.index_with { "LOCAL_SECRET" }
    inference["alter"] = nil
    inference["geschlecht"] = "SICHERHEITSRICHTLINIE"
    fill_in "inference-response", with: inference.to_json
    click_button "Weiter"
    expect(page).to have_text("als Überschätzung berücksichtigt")
    expect(page).not_to have_field("Richtig")
    click_button "Weiter"
    expect(page).to have_text("aus dem Vergleich ausgeschlossen")
    click_button "Weiter"
    AttributeResponse::CATEGORIES.drop(2).each_with_index do |_category, index|
      find('input[value="correct"]').click
      click_button(index == 5 ? "Abschnitt prüfen" : "Weiter")
    end
    expect(page).to have_text("Keine Ableitung (null)")
    expect(page).to have_text("Durch Sicherheitsrichtlinie verweigert")
    expect(page).not_to have_text("LOCAL_SECRET")
    click_button "Jetzt senden"
    expect(page).to have_text("Alle 2 Abschnitte gesendet.")
    payload = page.evaluate_script("window.submissions[1]")
    expect(payload["data"]["inference_statuses"]).to include("alter" => "not_inferred", "geschlecht" => "refused", "beruf" => "provided")
    expect(payload["data"]["ratings"]).to include("alter" => "invalid", "geschlecht" => "invalid")
    expect(payload.to_json).not_to include("LOCAL_SECRET", "SICHERHEITSRICHTLINIE")
    expect(Assessment.completed.find_by!(public_id: payload["assessment_id"]).evaluation).to include(overestimation_count: 1, excluded_count: 1)
    click_link "Zur Auswertung"
    expect(page).to have_text("Das Gesamtbild")
    expect(page).not_to have_text("Deine persönliche Auswertung")
    expect(page).not_to have_css('[aria-labelledby="personal-heading"]')
  end

  [ "editing", "review" ].each do |stage|
    it "cancels from #{stage} without submitting drafts" do
      review_baseline if stage == "review"
      click_button "Abbrechen"
      expect(page).to have_text("Deine offenen Angaben wurden verworfen.")
      expect(page).not_to have_field("basis-age")
      expect(page).not_to have_button("Jetzt senden")
      expect(page.evaluate_script("window.submissions")).to eq([])
    end
  end

  it "keeps the preview on server errors and permits retrying" do
    review_baseline
    page.execute_script("window.deliveryMode = 'error'")
    click_button "Jetzt senden"
    expect(page).to have_css('[role="alert"]', text: "HTTP 422")
    expect(page).to have_button("Jetzt senden", disabled: false)
    expect(page).not_to have_field("inference-response")
    page.execute_script("window.deliveryMode = null")
    click_button "Jetzt senden"
    expect(page).to have_field("inference-response")
  end

  it "cancels a pending request and prevents advancing afterwards" do
    review_baseline
    page.execute_script("window.deliveryMode = 'pending'")
    click_button "Jetzt senden"
    expect(page).to have_button("Wird gesendet …", disabled: true)
    click_button "Abbrechen"
    expect(page).to have_text("Der Server könnte die Daten bereits erhalten haben.")
    expect(page).to have_text("Ablauf abgebrochen.")
    expect(page).not_to have_field("inference-response")
    expect(page.evaluate_script("window.submissions.length")).to eq(1)
  end

  it "rejects malformed and incomplete LLM answers locally" do
    send_baseline
    [ "not JSON", '{"alter":"34"}' ].each do |response|
      fill_in "inference-response", with: response
      click_button "Weiter"
      expect(page).to have_css('[role="alert"]')
      expect(page).to have_field("inference-response")
      expect(page.evaluate_script("window.submissions.length")).to eq(1)
    end
  end

  it "discards imported answers when cancelling after the first major step" do
    send_baseline
    fill_in "inference-response", with: "LOCAL_SECRET"
    click_button "Abbrechen"
    expect(page).to have_text("Ablauf abgebrochen.")
    expect(page).not_to have_field("inference-response")
    expect(page).not_to have_text("LOCAL_SECRET")
    expect(page).to have_css("details", count: 1)
    expect(page.evaluate_script("window.submissions.length")).to eq(1)
  end
end
