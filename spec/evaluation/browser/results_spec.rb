require "rails_helper"
require_relative "../support/browser"

RSpec.describe "Results page", type: :feature do
  before do
    Capybara.current_driver = :assessment_chrome
    resize_evaluation_viewport(1280)
    allow(Rails.application.config.x).to receive(:results_min_participants).and_return(2)
  end

  after { Capybara.use_default_driver }

  def assessment(model: "ChatGPT", age_group: "25–34", excluded: false)
    Assessment.create!(public_id: SecureRandom.uuid, age_group: age_group, model: model, instrument_version: Assessment::INSTRUMENT_VERSION, completed_at: Time.current) do |record|
      AttributeResponse::CATEGORIES.each_with_index do |category, index|
        status = excluded ? "refused" : "provided"
        rating = excluded ? "invalid" : (index.even? ? "correct" : "incorrect")
        record.attribute_responses.build(category: category, expectation: index < 4 ? "yes" : "no", inference_status: status, rating: rating)
      end
    end
  end

  it "[UI-01] Gesperrte Ergebnisansicht mit Methodenerklärung anzeigen" do
    assessment
    visit "/result"
    expect(page).to have_text("Ergebnisse ab 2 abgeschlossenen Teilnahmen")
    expect(page).to have_text("So wird gerechnet")
    expect(page).to have_link("So wird die Awareness-Gap berechnet", exact: true)
    expect(find('a[href="#method"]').text).not_to include("↓")
    expect(page).not_to have_css("#overview")
    expect(page).not_to have_css("#categories")
    expect(page).not_to have_css("#groups")
    expect(page).not_to have_text("Deine persönliche Auswertung")
    expect(page.evaluate_script("JSON.parse(document.querySelector('[data-page]').dataset.page).props.results").keys).to contain_exactly("available", "minimum_participants", "instrument_version")
  end

  it "[UI-02] Kennzahlen und interaktive Gruppenansicht auf Desktop und schmalen Fenstern prüfen" do
    2.times { assessment }
    2.times { assessment(model: "Claude", age_group: "18–24") }
    visit "/result"
    expect(page).to have_text("4 abgeschlossene Teilnahmen")
    within("#overview") do
      expect(page).to have_text("50")
      expect(page).to have_text("16 von 32 auswertbaren Antworten")
    end
    expect(page).to have_select("category-view", selected: "Abweichung der Erwartungen")
    select "Erwartet und als richtig bestätigt", from: "category-view"
    within("#categories") { expect(page).to have_text("Als richtig bestätigt", count: 8) }
    select "Abweichung der Erwartungen", from: "category-view"
    select "Größte Awareness-Gap zuerst", from: "category-sort"
    within("#groups") do
      expect(page).to have_text("ChatGPT")
      expect(page).to have_text("Claude")
      expect(page).to have_text("18–24")
    end
    [ 320, 375, 768, 1280 ].each do |width|
      resize_evaluation_viewport(width)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true), "Horizontal overflow at #{width}px"
    end
    page.execute_script("window.scrollTo(0, 0)")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-desktop.png"))
    page.execute_script("document.querySelector('#overview').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-overview.png"))
    page.execute_script("document.querySelector('#categories').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-categories.png"))
    resize_evaluation_viewport(375)
    page.execute_script("window.scrollTo(0, 0)")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-mobile.png"))
    page.execute_script("document.querySelectorAll('nav a').forEach(link => { link.style.transition = 'none'; }); document.documentElement.classList.add('dark')")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-dark.png"))
    page.execute_script("document.querySelector('#categories').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-categories-dark.png"))
    resize_evaluation_viewport(1280)
    page.execute_script("document.querySelector('#groups').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-groups.png"))
    page.execute_script("document.querySelector('#method').scrollIntoView()")
    page.save_screenshot(File.join(ENV.fetch("EVALUATION_OUTPUT_DIR", "/tmp"), "alina-results-method.png"))
  end

  it "[UI-03] Undefinierte öffentliche Quoten verständlich kennzeichnen" do
    2.times { assessment(excluded: true) }
    visit "/result"
    within("#overview") do
      expect(page).to have_text("Nicht berechenbar", minimum: 3)
      expect(page).to have_text("0 von 0 auswertbaren Antworten", count: 3)
      expect(page).not_to have_text("NaN")
    end
  end

  it "[UI-04] Unzureichend große Gruppen auch in der Oberfläche zurückhalten" do
    2.times { assessment }
    assessment(model: "Claude", age_group: "18–24")
    visit "/result"
    within("#groups") do
      expect(page).to have_text("jede vertretene Gruppe mindestens 2 abgeschlossene Teilnahmen", count: 1)
      expect(page).not_to have_text("Nach Altersgruppe")
      expect(page).not_to have_css("table")
      expect(page).not_to have_text("Claude")
      expect(page).not_to have_text("18–24")
    end
  end
  it "[UI-05] Ergänzende Altersgruppenunterdrückung korrekt darstellen" do
    2.times { assessment(age_group: "25–34") }
    3.times { assessment(age_group: "35–44") }
    assessment(age_group: "18–24")
    visit "/result"
    within('section[aria-labelledby="age-groups-heading"]') do
      expect(page).to have_text("35–44")
      expect(page).not_to have_text("18–24")
      expect(page).not_to have_text("25–34")
      expect(page).to have_text("mindestens 2 abgeschlossenen Teilnahmen")
    end
    expect(page).not_to have_css('[aria-labelledby="personal-heading"]')
  end
end
