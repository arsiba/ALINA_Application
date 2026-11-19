require "rails_helper"

RSpec.describe "Results configuration" do
  around do |example|
    original = Rails.application.config.x.results_min_participants
    example.run
  ensure
    Rails.application.config.x.results_min_participants = original
  end

  it "[CFG-01] Positive ganzzahlige Freigabeschwelle übernehmen" do
    allow(ENV).to receive(:fetch).with("RESULTS_MIN_PARTICIPANTS", "10").and_return("27")
    load Rails.root.join("config/initializers/results.rb")
    expect(Rails.application.config.x.results_min_participants).to eq(27)
  end

  it "[CFG-02] Ungültige Freigabeschwellen beim Start zurückweisen" do
    [ "0", "-1", "1.5", "invalid", "" ].each do |value|
      allow(ENV).to receive(:fetch).with("RESULTS_MIN_PARTICIPANTS", "10").and_return(value)
      expect { load Rails.root.join("config/initializers/results.rb") }.to raise_error(ArgumentError)
    end
  end
end
