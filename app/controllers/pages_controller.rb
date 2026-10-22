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
    render inertia: "Result"
  end
end
