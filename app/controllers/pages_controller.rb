class PagesController < ApplicationController
  def home
    render inertia: "Home"
  end

  def about
    render inertia: "About"
  end

  def form
    render inertia: "Form"
  end

  def result
    response.headers["Cache-Control"] = "no-store"
    render inertia: "Result", props: { results: AssessmentResults.call }
  end
end
