module Evaluation
  module RequirementAssessment
    def self.classify(counts, scope:)
      passed = counts.fetch("BESTANDEN", 0)
      return "nicht erfüllt" if counts.fetch("FEHLGESCHLAGEN", 0).positive?
      return "nicht untersucht" if passed.zero?
      return "teilweise erfüllt" if scope == "partial" || counts.fetch("AUSSTEHEND", 0).positive?

      "erfüllt"
    end
  end
end
