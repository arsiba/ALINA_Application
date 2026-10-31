class FormSubmissionsController < ApplicationController
  def create
    unless valid_submission?
      return render json: { error: "Unbekannter Abschnitt oder ungültige Angaben." }, status: :unprocessable_content
    end

    public_id = params[:assessment_id].downcase
    if participation_cookies.participated? && !Assessment.completed.exists?(public_id: public_id)
      return render json: { error: "In diesem Browser wurde bereits eine Teilnahme abgeschlossen. Eine erneute Teilnahme ist nicht möglich." }, status: :conflict
    end

    if params[:step] == "baseline"
      AssessmentSubmission.baseline(public_id: public_id, data: params[:data])
    else
      AssessmentSubmission.evaluation(public_id: public_id, data: params[:data])
      participation_cookies.mark_participated
    end

    render json: { accepted: true, step: params[:step] }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Die zugehörige Befragung wurde nicht gefunden. Bitte sende zuerst die Basisdaten." }, status: :not_found
  rescue AssessmentSubmission::Conflict
    render json: { error: "Dieser Abschnitt wurde bereits mit anderen Angaben gespeichert." }, status: :conflict
  rescue ActiveRecord::RecordInvalid
    render json: { error: "Die Angaben konnten nicht gespeichert werden." }, status: :unprocessable_content
  end

  private

  def valid_submission?
    return false unless params[:assessment_id].is_a?(String) && params[:assessment_id].match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

    data = params[:data]
    case params[:step]
    when "baseline"
      exact_keys?(data, %w[basis expectations]) &&
        exact_keys?(data[:basis], %w[age_group model]) &&
        Assessment::AGE_GROUPS.include?(data[:basis][:age_group]) &&
        Assessment::MODELS.include?(data[:basis][:model]) &&
        valid_answers?(data[:expectations], AttributeResponse::EXPECTATIONS)
    when "evaluation"
      exact_keys?(data, %w[ratings inference_statuses]) &&
        valid_answers?(data[:ratings], AttributeResponse::RATINGS) &&
        valid_answers?(data[:inference_statuses], AttributeResponse::INFERENCE_STATUSES) &&
        AttributeResponse::CATEGORIES.all? do |category|
          data[:inference_statuses][category] == "provided" || data[:ratings][category] == "invalid"
        end
    else
      false
    end
  end

  def exact_keys?(data, keys)
    data.is_a?(ActionController::Parameters) && data.keys.sort == keys.sort
  end

  def valid_answers?(data, values)
    exact_keys?(data, AttributeResponse::CATEGORIES) && AttributeResponse::CATEGORIES.all? { |category| values.include?(data[category]) }
  end
end
