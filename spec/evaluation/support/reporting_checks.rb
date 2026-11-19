# Infrastructure checks are run explicitly by bin/test. They are not research
# evaluation cases and must not inflate the requirement-based result counts.
require "rspec/core"
require "rspec/expectations"
require "tmpdir"
require "stringio"
require "digest"
require "open3"
require "rbconfig"
require_relative "observations"
require_relative "formatter"

RSpec.describe "Evaluation reporting infrastructure" do
  it "classifies success, partial evidence, failure and missing evidence separately" do
    classify = Evaluation::RequirementAssessment.method(:classify)
    expect(classify.call({ "BESTANDEN" => 2 }, scope: "technical")).to eq("erfüllt")
    expect(classify.call({ "BESTANDEN" => 2 }, scope: "partial")).to eq("teilweise erfüllt")
    expect(classify.call({ "BESTANDEN" => 1, "AUSSTEHEND" => 1 }, scope: "technical")).to eq("teilweise erfüllt")
    expect(classify.call({ "BESTANDEN" => 1, "FEHLGESCHLAGEN" => 1 }, scope: "technical")).to eq("nicht erfüllt")
    expect(classify.call({ "NICHT UNTERSUCHT" => 1 }, scope: "partial")).to eq("nicht untersucht")
  end

  it "records actual values independently and preserves snapshots including undefined rates" do
    actual = { gap_rate: nil, counts: [ 1, 2 ] }
    expected = { gap_rate: nil, counts: [ 1, 3 ] }
    record_observation("Different values", expected: expected, actual: actual)
    actual[:counts] << 4
    observation = RSpec.current_example.metadata.fetch(:evaluation_observations).last
    expect(observation.fetch("actual")).to eq("gap_rate" => nil, "counts" => [ 1, 2 ])
    expect(observation.fetch("expected")).to eq("gap_rate" => nil, "counts" => [ 1, 3 ])
  end

  it "retains the mismatching actual value when a comparison fails" do
    expect { compare_observation("Mismatch", expected: 0.5, actual: 0.75) }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    expect(RSpec.current_example.metadata.fetch(:evaluation_observations).last).to include("actual" => 0.75, "expected" => 0.5)
  end

  it "prints and serializes observed values and a failed requirement classification" do
    Dir.mktmpdir("evaluation-reporting-") do |directory|
      previous_output = ENV["EVALUATION_OUTPUT_DIR"]
      ENV["EVALUATION_OUTPUT_DIR"] = directory
      begin
        output = StringIO.new
        formatter = Evaluation::Formatter.new(output)
        execution = Struct.new(:run_time, :pending_message).new(0.1, nil)
        example = Struct.new(:description, :metadata, :execution_result, :location, :exception).new(
          "[MOD-03] Fixture for reporting check",
          { evaluation_observations: [ { "label" => "gap_rate", "expected" => 0.5, "actual" => 0.75 } ] },
          execution, "reporting_checks.rb", RuntimeError.new("Deliberate infrastructure test failure")
        )
        formatter.record(example, "FEHLGESCHLAGEN")
        formatter.dump_summary(Struct.new(:duration).new(0.1))
        report = JSON.parse(File.read(File.join(directory, "evaluation.json")))
        expect(output.string).to include("Soll: 0.5 | Ist: 0.75", "Bewertung im dokumentierten Prüfumfang: nicht erfüllt")
        expect(report.fetch("cases").first.fetch("observations").first.fetch("actual")).to eq(0.75)
        expect(report.fetch("requirements").find { |row| row.fetch("id") == "FA-09" }.fetch("classification")).to eq("nicht erfüllt")
      ensure
        ENV["EVALUATION_OUTPUT_DIR"] = previous_output
      end
    end
  end

  it "generates a failure report with actual values instead of claiming successful evaluation" do
    Dir.mktmpdir("evaluation-failure-documentation-") do |directory|
      paths, status = Open3.capture2("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z")
      expect(status.success?).to be(true)
      inventory = paths.split("\0").uniq.sort.select { |path| File.file?(path) }.to_h { |path| [ path, Digest::SHA256.file(path).hexdigest ] }
      File.write(File.join(directory, "source-files.json"), JSON.generate(inventory))
      environment = { started_at_utc: "2026-01-01T00:00:00Z", git_commit: "infrastructure-fixture", source_sha256: "fixture", instrument_version: "fixture", chromium: "fixture" }
      File.write(File.join(directory, "environment.json"), JSON.generate(environment))
      report = {
        duration_seconds: 0.1, requirements: [],
        cases: [ { id: "INFRA", title: "Deliberate reporting failure", status: "FEHLGESCHLAGEN", observations: [ { label: "gap", expected: 0.5, actual: 0.75 } ] } ]
      }
      File.write(File.join(directory, "evaluation.json"), JSON.generate(report))
      stdout, stderr, status = Open3.capture3(
        { "EVALUATION_OUTPUT_DIR" => directory }, RbConfig.ruby, File.expand_path("result_documentation.rb", __dir__)
      )
      expect(status.success?).to be(true), "#{stdout}\n#{stderr}"
      text = File.read(File.join(directory, "AUSWERTUNG.md"))
      expect(text).to include("FEHLGESCHLAGEN", "| gap | 0.5 | 0.75 |", "nicht vollständig bestanden")
      expect(text).not_to include("Die Ergebnisse belegen die Erfüllung")
    end
  end
end
