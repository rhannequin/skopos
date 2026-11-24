# frozen_string_literal: true

class ProgrammesController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :show

  def show
    @programme = Programme.new(programme_params)
    @programme.validate if params.key?(:programme)
  end

  private

  def programme_params
    params.fetch(:programme, {}).permit(
      :observatory_code,
      :latitude,
      :longitude,
      :elevation,
      :aperture,
      :limiting_magnitude,
      :week_start,
      :targets_text
    )
  end
end
