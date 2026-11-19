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

# Quit before Capybara's reset hook: Chrome 158 rejects Capybara 3's wildcard
# Storage.clearDataForOrigin command. A fresh browser fully isolates examples.
RSpec.configure do |config|
  config.after(:each, type: :feature) do
    Capybara.using_driver(:assessment_chrome) { page.driver.quit }
  end
end
