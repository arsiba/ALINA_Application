require "rails_helper"
require "json"

RSpec.describe "Ergänzende Nachweise außerhalb der automatisierten Evaluation" do
  JSON.parse(File.read(File.expand_path("../catalog.json", __dir__))).select { |entry| entry.fetch("id").start_with?("MAN-") }.each do |entry|
    it "[#{entry.fetch('id')}] #{entry.fetch('title')}" do
      skip entry.fetch("expected")
    end
  end
end
