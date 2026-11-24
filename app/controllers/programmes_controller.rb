# frozen_string_literal: true

class ProgrammesController < ApplicationController
  rate_limit to: 30, within: 1.minute, only: :show

  BYTE_ORDER_MARK = "\uFEFF"

  helper_method :programme_params

  def show
    @programme = Programme.new(programme_params)
    @programme.validate if params.key?(:programme)

    respond_to do |format|
      format.html
      format.csv { send_csv }
    end
  end

  private

  def send_csv
    return head(:unprocessable_content) unless @programme.valid?

    export = Programme::CsvExport.new(@programme)

    send_data(
      BYTE_ORDER_MARK + export.to_csv,
      type: :csv,
      filename: export.filename
    )
  end

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
