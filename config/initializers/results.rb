minimum = Integer(ENV.fetch("RESULTS_MIN_PARTICIPANTS", "10"), 10)
raise ArgumentError, "RESULTS_MIN_PARTICIPANTS must be a positive integer" unless minimum.positive?

Rails.application.config.x.results_min_participants = minimum
