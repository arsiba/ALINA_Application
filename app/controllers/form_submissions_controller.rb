class FormSubmissionsController < ApplicationController
  ATTRIBUTES = %w[alter geschlecht beziehungsstatus wohnort geburtsort bildungsstand beruf einkommen].freeze
  AGE_GROUPS = [ "Unter 18", "18–24", "25–34", "35–44", "45–54", "55–64", "65 oder älter" ].freeze
  MODELS = [ "ChatGPT", "Claude", "Gemini", "Copilot", "Anderes" ].freeze

  def create
    data = params[:data]
    valid = case params[:step]
    when "baseline"
      exact_keys?(data, %w[basis expectations]) &&
        exact_keys?(data[:basis], %w[age_group model]) &&
        AGE_GROUPS.include?(data[:basis][:age_group]) &&
        MODELS.include?(data[:basis][:model]) &&
        valid_answers?(data[:expectations], %w[yes no])
    when "evaluation"
      exact_keys?(data, %w[ratings]) && valid_answers?(data[:ratings], %w[correct incorrect invalid])
    else
      false
    end

    valid &&= params[:assessment_id].is_a?(String) && params[:assessment_id].match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

    unless valid
      return render json: { error: "Unbekannter Abschnitt oder ungültige Angaben." }, status: :unprocessable_content
    end

    render json: { accepted: true, step: params[:step] }
  end

  private

  def exact_keys?(data, keys)
    data.is_a?(ActionController::Parameters) && data.keys.sort == keys.sort
  end

  def valid_answers?(data, values)
    exact_keys?(data, ATTRIBUTES) && ATTRIBUTES.all? { |attribute| values.include?(data[attribute]) }
  end
end
