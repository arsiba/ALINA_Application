require "json"
require "digest"
require "open3"
require "time"
require "rbconfig"
require_relative "../../../config/environment"

def command(*args)
  output, status = Open3.capture2e(*args)
  abort "Umgebungsnachweis fehlgeschlagen: #{args.first}: #{output}" unless status.success?
  output.strip
end

root = File.expand_path("../../..", __dir__)
Dir.chdir(root)
output = ENV.fetch("EVALUATION_OUTPUT_DIR")
files = command("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z").split("\0").uniq.sort.select { |path| File.file?(path) }
inventory = files.to_h { |path| [ path, Digest::SHA256.file(path).hexdigest ] }
File.write(File.join(output, "source-files.json"), JSON.pretty_generate(inventory) + "\n")
environment = {
  started_at_utc: Time.now.utc.iso8601,
  git_commit: command("git", "rev-parse", "HEAD"),
  git_status: command("git", "status", "--short"),
  source_sha256: Digest::SHA256.hexdigest(JSON.generate(inventory)),
  ruby: RUBY_DESCRIPTION,
  platform: RbConfig::CONFIG.fetch("host"),
  node: command("node", "--version"),
  npm: command("npm", "--version"),
  chromium: command("/usr/bin/chromium", "--version"),
  chromedriver: command("/usr/bin/chromedriver", "--version"),
  gems: %w[rails rspec-core rspec-rails capybara selenium-webdriver sqlite3].to_h { |name| [ name, Gem::Specification.find_by_name(name).version.to_s ] },
  instrument_version: Assessment::INSTRUMENT_VERSION,
  prompt_sha256: Digest::SHA256.file("spec/evaluation/fixtures/prompt_v1.txt").hexdigest,
  rails_env: ENV.fetch("RAILS_ENV"),
  browser_mode: "Headless Chromium; Selenium; synthetische Testdaten; keine externe LLM-Verbindung",
  window_widths_css_px: [ 320, 375, 640, 768, 1280 ],
  window_height_css_px: 900,
  physical_devices_tested: [],
  device_scope: "Desktop-Browser mit kontrollierten CSS-Viewports; keine realen Mobilgeräte und keine Touch-Emulation",
  automation_scope: "Lokaler Evaluationsrunner und optionaler Git-Pre-Commit-Hook; kein Nachweis serverseitiger CI oder Branchschutzregeln",
  viewport_control: "CDP Emulation.setDeviceMetricsOverride, mobile=false, deviceScaleFactor=1; innerWidth/innerHeight werden geprüft",
  results_min_participants_at_boot: Rails.application.config.x.results_min_participants,
  results_thresholds: "Default 10; einzelne Tests setzen explizit 1, 2, 27, 37 oder 100 bzw. ungültige Konfigurationswerte.",
  order: "defined",
  database: "SQLite storage/test.sqlite3; RSpec-Transaktionen; kein Produktionsdatenbestand",
  csrf: "Rails-Testumgebung deaktiviert CSRF-Prüfung; kein Nachweis des CSRF-Schutzes.",
  output_directory: output
}
File.write(File.join(output, "environment.json"), JSON.pretty_generate(environment) + "\n")
puts "UMGEBUNG UND SOFTWARESTAND"
environment.each { |key, value| puts "#{key}: #{value.is_a?(Hash) || value.is_a?(Array) ? JSON.generate(value) : value}" }
puts "Dateihashes einschließlich unversionierter Evaluationsdateien: source-files.json"
puts "Vorbereitung und Produktionsbuild: setup.log"
