require "json"
require "digest"
require "open3"
require "time"

output = ENV.fetch("EVALUATION_OUTPUT_DIR")
recorded = JSON.parse(File.read(File.join(output, "source-files.json")))
paths, status = Open3.capture2("git", "ls-files", "--cached", "--others", "--exclude-standard", "-z")
abort "Dateiliste konnte nicht geprüft werden." unless status.success?
current = paths.split("\0").uniq.sort.select { |path| File.file?(path) }.to_h { |path| [ path, Digest::SHA256.file(path).hexdigest ] }
changed = (recorded.keys | current.keys).select { |path| recorded[path] != current[path] }
abort "Softwarestand während des Laufs verändert: #{changed.join(', ')}. Vollständigen Lauf wiederholen." unless changed.empty?
environment_path = File.join(output, "environment.json")
environment = JSON.parse(File.read(environment_path))
environment["finished_at_utc"] = Time.now.utc.iso8601
environment["source_unchanged_during_run"] = true
File.write(environment_path, JSON.pretty_generate(environment) + "\n")
report = JSON.parse(File.read(File.join(output, "evaluation.json")))
counts = report.fetch("cases").map { |row| row.fetch("status") }.tally
text = <<~MD
  # Beobachtete Ergebnisse der technischen Evaluation

  Laufbeginn: #{environment.fetch('started_at_utc')}. Laufende: #{environment.fetch('finished_at_utc')}.

  Softwarestand: Git-Commit `#{environment.fetch('git_commit')}` zuzüglich des in `environment.json` dokumentierten Arbeitsstands. SHA-256 des Dateiinventars: `#{environment.fetch('source_sha256')}`. Die Dateien wurden am Ende erneut geprüft und waren während dieses Laufs unverändert. Einzelhashes stehen in `source-files.json`.

  Instrumentversion: #{environment.fetch('instrument_version')}. Browser: #{environment.fetch('chromium')}. Die tatsächlichen Viewportbreiten wurden in den Layoutprüfungen kontrolliert. Die Tests verwenden synthetische Daten und keine reale LLM-Verbindung.

  ## Beobachtete Prüfergebnisse

  | Status | Anzahl |
  |---|---:|
MD
counts.each { |key, value| text << "| #{key} | #{value} |\n" }
text << "\nAusführungsdauer der RSpec-Tests: #{format('%.3f', report.fetch('duration_seconds'))} Sekunden. Diese Dauer ist keine Performancekennzahl der Anwendung.\n"
text << "\nDie Node-Tests werden durch einzelne RSpec-Beispiele aufgerufen und sind in diesen Zahlen bereits enthalten. Die vier MAN-Fälle sind ausdrücklich nicht untersuchte Nachweise; sie werden nicht zu den bestandenen automatisierten Fällen gezählt.\n"
text << "\n## Einordnung je Anforderung\n\nBewertungen gelten für den dokumentierten Prüfumfang. Technische Nachweise ersetzen keine offenen empirischen Untersuchungen.\n\n| ID | Anforderung | Bewertung | Beobachteter Status | Reichweite |\n|---|---|---|---|---|\n"
report.fetch("requirements").each do |row|
  values = [ row.fetch("id"), row.fetch("title"), row.fetch("classification"), "#{row.fetch('verdict')} (#{row.fetch('counts').map { |key, value| "#{value} #{key}" }.join('; ')})", row.fetch("limit") ]
  text << "| #{values.map { |value| value.gsub('|', '\\|').gsub("\n", '<br>') }.join(' | ')} |\n"
end
text << "\n## Protokollierte Soll- und Istwerte\n\nDie folgenden Werte werden aus den tatsächlich geprüften Ergebnissen übernommen. Fehlende Werte bei anderen Fällen bedeuten, dass dort nur der Assertion-Prüfstatus dokumentiert wird.\n"
report.fetch("cases").each do |row|
  observations = row.fetch("observations", [])
  next if observations.empty?

  text << "\n### #{row.fetch('id')}: #{row.fetch('title')}\n\n| Messgröße | Soll | Ist |\n|---|---|---|\n"
  observations.each do |observation|
    values = [ observation.fetch("label"), JSON.generate(observation.fetch("expected")), JSON.generate(observation.fetch("actual")) ]
    text << "| #{values.map { |value| value.gsub('|', '\\|').gsub("\n", '<br>') }.join(' | ')} |\n"
  end
end
text << "\n## Offene Nachweise\n\n"
report.fetch("cases").select { |row| row.fetch("status") == "NICHT UNTERSUCHT" }.each do |row|
  text << "- **#{row.fetch('id')}: #{row.fetch('title')}** – #{row.fetch('reason')}\n"
end
text << "\n## Verwendung in der Arbeit\n\n"
conclusion = counts.fetch("FEHLGESCHLAGEN", 0).positive? || counts.fetch("AUSSTEHEND", 0).positive? ? "Die technische Prüfung ist nicht vollständig bestanden; die betroffenen Fälle und Anforderungen sind im Bericht ausgewiesen." : "Die Ergebnisse belegen die Erfüllung der definierten technischen Prüfkriterien in der dokumentierten Umgebung."
text << "#{conclusion} Sie rechtfertigen keine pauschale Gleichsetzung von Testbestehen und vollständiger Erfüllung aller Qualitätsanforderungen. Die Auswertung beruht auf synthetischen Fällen und fest vorgegebenen Sollwerten.\n\n"
text << "Für Methoden und Kriterien die versionierte Datei `spec/evaluation/KRITERIEN.md` und die zugehörige README heranziehen. Für den Anhang `protocol.txt` verwenden; die strukturierten Dateien und den Softwarestand zusammen archivieren. Screenshots sind ergänzende, nicht automatisch visuell bewertete Artefakte.\n"
File.write(File.join(output, "AUSWERTUNG.md"), text)
puts "Softwarestand am Laufende unverändert bestätigt."
puts "Ergebnistabelle für das Evaluationskapitel: #{File.join(output, 'AUSWERTUNG.md')}"
