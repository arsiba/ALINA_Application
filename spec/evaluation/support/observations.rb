require "json"

module Evaluation
  module Observations
    def record_observation(label, expected:, actual:)
      # Keep an immutable JSON snapshot, even if the tested object changes later.
      observation = JSON.parse(JSON.generate(label: label, expected: expected, actual: actual))
      (RSpec.current_example.metadata[:evaluation_observations] ||= []) << observation
    end

    def compare_observation(label, expected:, actual:)
      record_observation(label, expected: expected, actual: actual)
      expect(actual).to eq(expected)
    end

    def compare_metrics(label, expected:, actual:)
      expected.each do |key, value|
        compare_observation("#{label}: #{key}", expected: value, actual: actual.fetch(key))
      end
    end
  end
end

RSpec.configure do |config|
  config.include Evaluation::Observations
end
