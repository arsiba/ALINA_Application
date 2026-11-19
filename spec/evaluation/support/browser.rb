require "capybara/rspec"
require "selenium-webdriver"

Capybara.app = Rails.application
Capybara.register_driver :assessment_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = "/usr/bin/chromium"
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  service = Selenium::WebDriver::Chrome::Service.new(path: "/usr/bin/chromedriver")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options, service: service)
end

module EvaluationBrowserViewport
  def resize_evaluation_viewport(width)
    page.driver.browser.manage.window.resize_to(width, 900)
    # Headless Chromium can impose a minimum outer window width. CDP sets
    # the actual CSS viewport, so a nominal 320px test really exercises 320px.
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: 900, deviceScaleFactor: 1, mobile: false)
    expect(page.evaluate_script("window.innerWidth")).to eq(width)
    expect(page.evaluate_script("window.innerHeight")).to eq(900)
  end
end

RSpec.configure do |config|
  config.include EvaluationBrowserViewport, type: :feature
end
