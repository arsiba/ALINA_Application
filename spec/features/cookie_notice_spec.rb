require "rails_helper"
require_relative "../support/browser"

RSpec.describe "Cookie notice", type: :feature do
  before do
    Capybara.current_driver = :assessment_chrome
    visit "/"
  end

  after { Capybara.use_default_driver }

  it "informs before participation and keeps acknowledgement out of cookies and browser storage" do
    expect(page).to have_css('section[aria-labelledby="cookie-heading"]')
    within('section[aria-labelledby="cookie-heading"]') do
      expect(page).to have_text("Technisch notwendige Cookies")
      expect(page).to have_text("30 Tage")
      expect(page).to have_text("keine Einwilligungsabfrage")
      expect(page).not_to have_button("Akzeptieren")
      expect(page).not_to have_button("Ablehnen")
    end
    expect(page.driver.browser.manage.all_cookies.map { |cookie| cookie[:name] }.grep(/^alina_/)).to be_empty
    click_button "Verstanden"
    expect(page).not_to have_css('section[aria-labelledby="cookie-heading"]')
    expect(page.driver.browser.manage.all_cookies.map { |cookie| cookie[:name] }.grep(/^alina_/)).to be_empty
    expect(page.evaluate_script("Object.keys(localStorage).concat(Object.keys(sessionStorage))")).to be_empty
    click_link "Form"
    expect(page).to have_text("Bevor du beginnst")
    expect(page).not_to have_css('section[aria-labelledby="cookie-heading"]')
    page.refresh
    expect(page).to have_css('section[aria-labelledby="cookie-heading"]')
  end

  it "provides a keyboard-accessible way to reopen the notice and explains its legal basis" do
    click_button "Verstanden"
    click_button "Cookie-Hinweis anzeigen"
    expect(page).to have_css('section[aria-labelledby="cookie-heading"]')
    expect(page.evaluate_script("document.activeElement.id")).to eq("cookie-heading")
    click_button "Verstanden"
    expect(page.evaluate_script("document.activeElement.textContent")).to eq("Cookie-Hinweis anzeigen")
    click_link "Cookie-Hinweise", exact: true
    expect(page).to have_css("h1", text: "Was dein Browser speichert")
    expect(page).to have_text("alina_participated=1")
    expect(page).to have_text("§ 25 Abs. 2 Nr. 2")
    expect(page).to have_text("Browser, nicht auf eine identifizierte Person")
  end

  it "fits desktop and narrow mobile screens without covering the page" do
    [ 320, 375, 768, 1280 ].each do |width|
      page.driver.browser.manage.window.resize_to(width, 900)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
    page.save_screenshot("/tmp/alina-cookie-notice-desktop.png")
    page.driver.browser.manage.window.resize_to(375, 900)
    page.save_screenshot("/tmp/alina-cookie-notice-mobile.png")
    page.execute_script("document.querySelectorAll('nav a').forEach(link => { link.style.transition = 'none'; }); document.documentElement.classList.add('dark')")
    page.save_screenshot("/tmp/alina-cookie-notice-dark.png")
  end
end
