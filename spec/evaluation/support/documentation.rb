require "json"

root = File.expand_path("..", __dir__)
cases = JSON.parse(File.read(File.join(root, "catalog.json")))
requirements = JSON.parse(File.read(File.join(root, "requirements.json")))
def cell(value)
  value.to_s.gsub("|", "\\|").gsub("\n", "<br>")
end
text = <<~MD
  # Kriterien- und Testfallmatrix der Evaluation

  Diese Matrix operationalisiert die funktionalen Anforderungen FA-01 bis FA-13 und Qualitätsanforderungen QA-01 bis QA-07 aus Kapitel 3.2/3.3 der Arbeit. Die Nummern folgen der dortigen Reihenfolge. DS-01 bis DS-03 konkretisieren zusätzlich den Prüfbereich Datenfluss aus Kapitel 6.1. DS-04 dokumentiert ergänzend das implementierte Teilnahmeflag; es ist keine zusätzliche ursprüngliche Qualitätsanforderung.

  **Dies ist der Prüfplan, kein Ergebnisprotokoll.** Beobachtete Ergebnisse und Fehler stehen erst nach einem Lauf in `protocol.txt` und `evaluation.json`; die numerischen Referenzfälle und JavaScript-Prüfungen enthalten zusätzlich getrennt erfasste Soll-/Istwerte. Ein bestandener Fall bestätigt seine Assertions für die angegebenen Eingaben. Offene empirische Nachweise stehen als MAN-Fälle ausdrücklich im Katalog.

  ## Anforderungen und Nachweisgrenzen

  | ID | Anforderung | Zugeordnete Prüffälle | Reichweite und offene Nachweise |
  |---|---|---|---|
MD
requirements.each do |row|
  ids = cases.select { |entry| entry.fetch("requirements").include?(row.fetch("id")) }.map { |entry| entry.fetch("id") }
  text << "| #{[ row.fetch('id'), row.fetch('title'), ids.join(', '), row.fetch('limit') ].map { |value| cell(value) }.join(' | ')} |\n"
end
cases.group_by { |row| row.fetch("section") }.sort.each do |section, entries|
  text << "\n## #{section}\n\n"
  text << "| Test-ID / Kriterium | Anforderungen | Verfahren | Ausgangszustand und Eingabe | Sollverhalten / Entscheidungsregel | Aussagegrenze | Implementierung |\n"
  text << "|---|---|---|---|---|---|---|\n"
  entries.each do |row|
    values = [ "#{row.fetch('id')}: #{row.fetch('title')}", row.fetch("requirements").join(", "), row.fetch("method"), row.fetch("given"), row.fetch("expected"), row.fetch("limit"), "[#{File.basename(row.fetch('file'))}](../../#{row.fetch('file')})" ]
    text << "| #{values.map { |value| cell(value) }.join(' | ')} |\n"
  end
end
text << "\nGesamt: #{cases.size} katalogisierte Prüffälle, davon #{cases.count { |row| row.fetch('id').start_with?('MAN-') }} ausdrücklich nicht automatisiert untersuchte Nachweise.\n"
File.write(File.join(root, "KRITERIEN.md"), text)
puts "KRITERIEN.md aus catalog.json und requirements.json aktualisiert."
