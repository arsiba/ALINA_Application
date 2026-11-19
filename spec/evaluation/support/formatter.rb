require "json"
require "rspec/core/formatters/base_text_formatter"
require_relative "requirement_assessment"

module Evaluation
  class Formatter < RSpec::Core::Formatters::BaseTextFormatter
    RSpec::Core::Formatters.register self, :start, :example_passed, :example_failed, :example_pending, :dump_summary

    def initialize(output)
      super
      @catalog = JSON.parse(File.read(File.expand_path("../catalog.json", __dir__))).to_h { |row| [ row.fetch("id"), row ] }
      @requirements = JSON.parse(File.read(File.expand_path("../requirements.json", __dir__)))
      @results = []
      @section = nil
    end

    def identifier(example)
      example.description[/\A\[([^\]]+)\]/, 1]
    end

    def start(notification)
      examples = RSpec.world.all_examples
      ids = examples.map { |example| identifier(example) }
      unless ids.compact.sort == @catalog.keys.sort && ids.uniq.size == ids.size
        raise ArgumentError, "Evaluationskatalog und Tests stimmen nicht überein. Fehlend: #{@catalog.keys - ids}; unbekannt: #{ids - @catalog.keys}; doppelte IDs: #{ids.tally.select { |_id, count| count > 1 }.keys}"
      end
      output.puts "\nANFORDERUNGSBASIERTE TECHNISCHE EVALUATION"
      output.puts "#{notification.count} Prüffälle einschließlich ausdrücklich nicht untersuchter Nachweise."
      output.puts "BESTANDEN bedeutet: Die aufgeführten Assertions des technischen Prüffalls sind erfüllt."
      output.puts "NICHT UNTERSUCHT bedeutet: Es liegt kein entsprechender empirischer Nachweis vor."
      output.puts "Die Anforderungsübersicht am Ende nennt die Grenzen der Nachweise."
    end

    def example_passed(notification)
      record(notification.example, "BESTANDEN")
    end

    def example_failed(notification)
      record(notification.example, "FEHLGESCHLAGEN")
    end

    def example_pending(notification)
      record(notification.example, identifier(notification.example).start_with?("MAN-") ? "NICHT UNTERSUCHT" : "AUSSTEHEND")
    end

    def record(example, status)
      row = @catalog.fetch(identifier(example))
      if @section != row.fetch("section")
        @section = row.fetch("section")
        output.puts "\n=== #{@section} ==="
      end
      result = row.merge(
        status: status, duration_seconds: example.execution_result.run_time,
        location: example.location,
        reason: example.execution_result.pending_message,
        observations: example.metadata.fetch(:evaluation_observations, []),
        failure: example.exception&.message
      )
      @results << result
      output.puts "\n[#{row.fetch('id')}] #{row.fetch('title')}"
      output.puts "  Anforderungen: #{row.fetch('requirements').join(', ')}"
      output.puts "  Verfahren: #{row.fetch('method')}"
      output.puts "  Ausgangszustand / Eingabe: #{row.fetch('given')}"
      output.puts "  Sollverhalten: #{row.fetch('expected')}"
      output.puts "  Ergebnis: #{status} (#{format('%.3f', example.execution_result.run_time)} s)"
      output.puts "  Beobachtung: Alle Assertions des Prüffalls erfüllt." if status == "BESTANDEN"
      result.fetch(:observations).each do |observation|
        output.puts "  Messwert: #{observation.fetch('label')} | Soll: #{JSON.generate(observation.fetch('expected'))} | Ist: #{JSON.generate(observation.fetch('actual'))}"
      end
      output.puts "  Begründung: #{example.execution_result.pending_message}" if example.execution_result.pending_message
      output.puts "  Fehler: #{example.exception.message}" if example.exception
      output.puts "  Aussagegrenze: #{row.fetch('limit')}"
      output.puts "  Quelle: #{example.location}"
      output.flush
    end

    def dump_summary(notification)
      output.puts "\n=== Anforderungen und Reichweite der Nachweise ==="
      summaries = @requirements.map do |requirement|
        rows = @results.select { |result| result.fetch("requirements").include?(requirement.fetch("id")) }
        counts = rows.map { |row| row.fetch(:status) }.tally
        classification = RequirementAssessment.classify(counts, scope: requirement.fetch("scope"))
        verdict = if counts.fetch("FEHLGESCHLAGEN", 0).positive?
          "Technische Kriterien nicht vollständig bestanden"
        elsif counts.fetch("AUSSTEHEND", 0).positive?
          "Technische Prüfung unvollständig"
        elsif counts.fetch("BESTANDEN", 0).zero?
          "Nicht untersucht"
        elsif requirement.fetch("scope") == "partial"
          "Teilweise technisch geprüft; ergänzender Nachweis offen"
        else
          "Definierte technische Kriterien bestanden"
        end
        output.puts "#{requirement.fetch('id')} – #{requirement.fetch('title')}: #{verdict}"
        output.puts "  Bewertung im dokumentierten Prüfumfang: #{classification}"
        output.puts "  Prüffälle: #{rows.map { |row| row.fetch('id') }.join(', ')}"
        output.puts "  Status: #{counts.map { |key, value| "#{value} #{key}" }.join('; ')}"
        output.puts "  Einordnung: #{requirement.fetch('limit')}"
        requirement.merge(classification: classification, verdict: verdict, counts: counts, cases: rows.map { |row| row.fetch("id") })
      end
      output.puts "\n=== Gesamtergebnis ==="
      @results.map { |row| row.fetch(:status) }.tally.each { |status, count| output.puts "#{status}: #{count}" }
      output.puts "Dauer der Tests: #{format('%.3f', notification.duration)} s"
      output.puts "Keine Nutzungsstudie, keine Last-/Betriebsstudie, keine allgemeine Gerätefreigabe und kein Nachweis vollständiger Anonymität."
      if ENV["EVALUATION_OUTPUT_DIR"]
        path = File.join(ENV.fetch("EVALUATION_OUTPUT_DIR"), "evaluation.json")
        File.write(path, JSON.pretty_generate({ requirements: summaries, cases: @results, duration_seconds: notification.duration }) + "\n")
      end
    end
  end
end
