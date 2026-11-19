require "rails_helper"
require_relative "../support/observations"
require "json"
require "open3"

RSpec.describe "Frontend-Verträge und persönliche Kennzahlen" do
  catalog = JSON.parse(File.read(File.expand_path("../catalog.json", __dir__)))
  catalog.select { |entry| entry.fetch("id").start_with?("JS-") }.each do |entry|
    it "[#{entry.fetch('id')}] #{entry.fetch('title')}" do
      test_file = entry.fetch("id").delete_prefix("JS-").to_i <= 4 ? "personal_score.test.js" : "contracts.test.js"
      stdout, stderr, status = Open3.capture3(
        "node", "--test", "--experimental-test-isolation=none", "--test-reporter=tap", "--test-name-pattern", "^\\[#{entry.fetch('id')}\\]",
        Rails.root.join("spec/evaluation/frontend", test_file).to_s
      )
      stdout.each_line do |line|
        match = line.match(/EVALUATION_OBSERVATION (\{.*\})/)
        next unless match

        observation = JSON.parse(match[1])
        record_observation(observation.fetch("label"), expected: observation.fetch("expected"), actual: observation.fetch("actual"))
      end
      expect(RSpec.current_example.metadata.fetch(:evaluation_observations, [])).not_to be_empty
      expect(status.success?).to be(true), "Node-Test fehlgeschlagen:\n#{stdout}\n#{stderr}"
      expect(stdout).to include("# Subtest: [#{entry.fetch('id')}]")
      expect(stdout).to match(/# pass 1\b/), "Erwartet genau einen ausgeführten Node-Test:\n#{stdout}"
    end
  end
end
