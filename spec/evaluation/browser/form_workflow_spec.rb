require "rails_helper"
require_relative "../support/observations"
require_relative "../support/browser"

RSpec.describe "Assessment workflow", type: :feature do
  before do
    Capybara.current_driver = :assessment_chrome
    resize_evaluation_viewport(1280)
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

  it "[FLOW-01] Hinweise vor Basisdaten und Rücknavigation ohne Übertragung" do
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
      resize_evaluation_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), "Horizontal overflow at #{width}px"
      page.all("main button").each do |button|
        expect(button.rect.height).to be >= 44
      end
    end
  end

  it "[FLOW-02] Workflow bei fünf Fensterbreiten auf Überlauf und Schaltflächen prüfen" do
    check_responsive_layout
    resize_evaluation_viewport(375)
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-disclaimer-mobile.png"))
    click_button "Weiter zu den Basisdaten"
    check_responsive_layout
    select "25–34", from: "basis-age"
    select "ChatGPT", from: "basis-model"
    click_button "Weiter"
    check_responsive_layout
    resize_evaluation_viewport(375)
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-expectation-mobile.png"))
    answer_questions("yes")
    check_responsive_layout
    click_button "Jetzt senden"
    expect(page).to have_field("inference-response")
    check_responsive_layout
    inference = AttributeResponse::CATEGORIES.index_with { "32–34 Jahre" }
    fill_in "inference-response", with: inference.to_json
    click_button "Weiter"
    check_responsive_layout
    resize_evaluation_viewport(375)
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-validation-mobile.png"))
    resize_evaluation_viewport(1280)
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-validation-desktop.png"))
  end

  it "[FLOW-03] Einzelfragen, Pflichtantwort und Rücknavigation prüfen" do
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

  it "[FLOW-04] Vollständigen Ablauf mit lokalem Inferenzmarker durchlaufen" do
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
    within('section[aria-labelledby="personal-score-heading"]') do
      expect(page).to have_css('[data-testid="awareness-score"]', text: "100")
      expect(page).to have_text("Nur jetzt verfügbar")
      expect(page).to have_text("nicht separat gespeichert")
      expect(page).to have_text("Nach dem Neuladen oder Verlassen dieser Seite")
      expect(page).not_to have_text("LOCAL_SECRET")
    end
    expect(page).to have_css('section[aria-label="Gesendete Abschnitte"] details', count: 2)
  end

  it "[FLOW-05] Nicht-Ableitung und Verweigerung im Workflow unterscheiden" do
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
    within('section[aria-labelledby="personal-score-heading"]') do
      expect(page).to have_css('[data-testid="awareness-score"]', text: "85,7")
      expect(page).to have_text("6 von 7 auswertbaren Kategorien")
    end
    click_link "Zur Gesamtauswertung"
    expect(page).to have_text("Das Gesamtbild")
    expect(page).not_to have_text("Deine persönliche Auswertung")
    expect(page).not_to have_css('[aria-labelledby="personal-score-heading"]')
  end

  it "[FLOW-06] Persönlichen Score erst nach Erfolg zeigen und bei Reload verwerfen" do
    allow(Rails.application.config.x).to receive(:results_min_participants).and_return(100)
    send_baseline
    fill_in "inference-response", with: AttributeResponse::CATEGORIES.index_with { "LOCAL_SECRET" }.to_json
    click_button "Weiter"
    answer_questions("correct")
    expect(page).not_to have_css('[aria-labelledby="personal-score-heading"]')
    page.execute_script("window.deliveryMode = 'error'")
    click_button "Jetzt senden"
    expect(page).to have_css('[role="alert"]', text: "HTTP 422")
    expect(page).not_to have_css('[aria-labelledby="personal-score-heading"]')
    page.execute_script("window.deliveryMode = null")
    click_button "Jetzt senden"
    expect(page).to have_css('[data-testid="awareness-score"]', text: "100")
    expect(page).to have_text("Nur jetzt verfügbar")
    marker = page.driver.browser.manage.all_cookies.find { |cookie| cookie[:name] == "alina_participated" }
    expect(marker[:value]).to eq("1")
    expect(page.evaluate_script("document.cookie")).not_to include("alina_participated")
    expect(page.evaluate_script("JSON.stringify(window.history.state)")).not_to include("awareness-score", "agreement_count", "LOCAL_SECRET")
    check_responsive_layout
    page.execute_script("document.querySelector('#personal-score-heading').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-personal-score-desktop.png"))
    resize_evaluation_viewport(375)
    page.execute_script("document.querySelector('#personal-score-heading').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-personal-score-mobile.png"))
    page.refresh
    expect(page).to have_text("In diesem Browser wurde bereits teilgenommen")
    expect(page).not_to have_css('[aria-labelledby="personal-score-heading"]')
    expect(page).not_to have_text("LOCAL_SECRET")
  end

  it "[FLOW-07] Bei vollständig ausgeschlossenen Antworten keinen persönlichen Score anzeigen" do
    send_baseline
    fill_in "inference-response", with: AttributeResponse::CATEGORIES.index_with { "SICHERHEITSRICHTLINIE" }.to_json
    click_button "Weiter"
    AttributeResponse::CATEGORIES.each_with_index do |_category, index|
      expect(page).to have_checked_field("Ungültig / Enthaltung")
      click_button(index == 7 ? "Abschnitt prüfen" : "Weiter")
    end
    click_button "Jetzt senden"
    within('section[aria-labelledby="personal-score-heading"]') do
      expect(page).to have_css('[data-testid="awareness-score"]', text: "Nicht berechenbar")
      expect(page).to have_text("Keine der acht Kategorien ist auswertbar")
      expect(page).to have_text("8 ausgeschlossen")
    end
  end

  [ "editing", "review" ].each do |stage|
    it "[FLOW-08-#{stage}] Abbruch aus #{stage} verwirft ungesendete Angaben" do
      review_baseline if stage == "review"
      click_button "Abbrechen"
      expect(page).to have_text("Deine offenen Angaben wurden verworfen.")
      expect(page).not_to have_field("basis-age")
      expect(page).not_to have_button("Jetzt senden")
      expect(page.evaluate_script("window.submissions")).to eq([])
    end
  end

  it "[FLOW-09] Serverfehler erhält Vorschau und erlaubt Wiederholung" do
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

  it "[FLOW-10] Laufende Anfrage abbrechen und spätes Weitergehen verhindern" do
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

  it "[FLOW-11] Ungültige LLM-Antworten lokal zurückweisen" do
    send_baseline
    [ "not JSON", '{"alter":"34"}' ].each do |response|
      fill_in "inference-response", with: response
      click_button "Weiter"
      expect(page).to have_css('[role="alert"]')
      expect(page).to have_field("inference-response")
      expect(page.evaluate_script("window.submissions.length")).to eq(1)
    end
  end

  it "[FLOW-12] Importierten Entwurf beim Abbruch verwerfen" do
    send_baseline
    fill_in "inference-response", with: "LOCAL_SECRET"
    click_button "Abbrechen"
    expect(page).to have_text("Ablauf abgebrochen.")
    expect(page).not_to have_field("inference-response")
    expect(page).not_to have_text("LOCAL_SECRET")
    expect(page).to have_css("details", count: 1)
    expect(page.evaluate_script("window.submissions.length")).to eq(1)
  end

  it "[FLOW-13] Einheitlichen, unveränderbaren Prompt der Instrumentversion bereitstellen" do
    send_baseline
    prompt = find("#inference-prompt")
    expect(prompt[:readonly]).to be_truthy
    expect(prompt.value).to eq(File.read(Rails.root.join("spec/evaluation/fixtures/prompt_v1.txt")))
    expect(page.evaluate_script("window.submissions.length")).to eq(1)
  end

  def visible_preview
    page.evaluate_script <<~JS
      (() => {
        const result = {};
        function collect(dl, path) {
          for (const row of dl.querySelectorAll(':scope > div')) {
            const key = row.querySelector(':scope > dt').textContent.trim();
            const dd = row.querySelector(':scope > dd');
            const nested = dd.querySelector('dl');
            const next = [...path, key];
            if (nested) collect(nested, next);
            else result[next.join(' / ')] = dd.textContent.trim();
          }
        }
        collect(document.querySelector('section[aria-labelledby="workflow-heading"] dl'), []);
        return result;
      })()
    JS
  end

  def readable_payload(payload, path = [])
    labels = {
      "assessment_id" => "Befragungskennung", "step" => "Abschnitt", "data" => "Angaben",
      "basis" => "Basisdaten", "age_group" => "Altersgruppe", "model" => "Verwendetes LLM",
      "expectations" => "Erwartung einer korrekten Ableitung", "ratings" => "Bewertung der LLM-Angaben",
      "inference_statuses" => "Auskunftsstatus je Kategorie",
      "alter" => "Alter", "geschlecht" => "Geschlecht", "beziehungsstatus" => "Beziehungsstatus",
      "wohnort" => "Wohnort", "geburtsort" => "Geburtsort", "bildungsstand" => "Bildungsstand",
      "beruf" => "Beruf", "einkommen" => "Einkommen"
    }
    values = {
      "baseline" => "Basisdaten und Erwartungen", "evaluation" => "LLM-Auskunft und Bewertung",
      "yes" => "Ja", "no" => "Nein", "correct" => "Richtig", "incorrect" => "Falsch",
      "invalid" => "Ungültig / Enthaltung", "provided" => "Angabe vorhanden",
      "not_inferred" => "Keine Ableitung (null)", "refused" => "Durch Sicherheitsrichtlinie verweigert"
    }
    payload.each_with_object({}) do |(key, value), result|
      current = path + [ labels.fetch(key) ]
      if value.is_a?(Hash)
        result.merge!(readable_payload(value, current))
      else
        result[current.join(" / ")] = values.fetch(value, value)
      end
    end
  end

  it "[FLOW-14] Sichtbare Vorschau vollständig mit beiden tatsächlichen Payloads abgleichen" do
    buffer = StringIO.new
    logger = ActiveSupport::Logger.new(buffer)
    Rails.logger.broadcast_to(logger)
    begin
      review_baseline
      baseline_preview = visible_preview
      expect(baseline_preview.size).to eq(12)
      click_button "Jetzt senden"
      expect(page).to have_field("inference-response")
      compare_observation("Basisvorschau und Request", expected: baseline_preview, actual: readable_payload(page.evaluate_script("window.submissions[0]")))

      categories = %w[alter geschlecht beziehungsstatus wohnort geburtsort bildungsstand beruf einkommen]
      inference = categories.index_with { |category| "EVAL_LOCAL_#{category}" }
      inference["alter"] = nil
      inference["geschlecht"] = "SICHERHEITSRICHTLINIE"
      fill_in "inference-response", with: inference.to_json
      click_button "Weiter"
      categories.each_with_index do |category, index|
        if index > 1
          expect(page).to have_css("blockquote", exact_text: "EVAL_LOCAL_#{category}")
          (categories.drop(2) - [ category ]).each { |other| expect(page).not_to have_css("blockquote", exact_text: "EVAL_LOCAL_#{other}") }
          find("input[value='#{%w[correct incorrect invalid][index % 3]}']").click
        end
        click_button(index == 7 ? "Abschnitt prüfen" : "Weiter")
      end
      evaluation_preview = visible_preview
      expect(evaluation_preview.size).to eq(18)
      expect(page).not_to have_text("EVAL_LOCAL_")
      expect(page.evaluate_script("window.submissions.length")).to eq(1)
      click_button "Jetzt senden"
      expect(page).to have_text("Alle 2 Abschnitte gesendet.")
      payloads = page.evaluate_script("window.submissions")
      compare_observation("Bewertungsvorschau und Request", expected: evaluation_preview, actual: readable_payload(payloads[1]))
      expect(payloads.to_json).not_to include("EVAL_LOCAL_")
      record = Assessment.completed.find_by!(public_id: payloads[0]["assessment_id"])
      persisted = record.attributes.to_json + record.attribute_responses.map(&:attributes).to_json
      compare_observation("Inferenzmarker in Requests", expected: false, actual: payloads.to_json.include?("EVAL_LOCAL_"))
      compare_observation("Inferenzmarker in Datensätzen", expected: false, actual: persisted.include?("EVAL_LOCAL_"))
      expect(buffer.string).to include("FormSubmissionsController", "[FILTERED]")
      compare_observation("Inferenzmarker in Rails-Logs desselben Ablaufs", expected: false, actual: buffer.string.include?("EVAL_LOCAL_"))
    ensure
      Rails.logger.stop_broadcasting_to(logger)
    end
  end
end
