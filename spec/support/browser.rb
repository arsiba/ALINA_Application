require "capybara/rspec"
require "selenium-webdriver"

# Chrome 158 rejects Capybara 3's wildcard Storage.clearDataForOrigin reset.
# A fresh browser also isolates cookies, permissions and all browser storage.
class IsolatedChromeDriver < Capybara::Selenium::Driver
  def reset!
    quit
  end
end

Capybara.app = Rails.application
Capybara.register_driver :assessment_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = "/usr/bin/chromium"
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  service = Selenium::WebDriver::Chrome::Service.new(path: "/usr/bin/chromedriver")
  IsolatedChromeDriver.new(app, browser: :chrome, options: options, service: service)
end
