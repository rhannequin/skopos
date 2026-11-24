# frozen_string_literal: true

class Programme::CsvExport
  FORMULA_START = /\A[=+\-@\t\r]/

  def initialize(programme)
    @programme = programme
  end

  def to_csv
    CSV.generate do |csv|
      csv << I18n.t("programmes.csv.headers")

      @programme.nights.each do |night|
        @programme.visibilities(night).each do |visibility|
          csv << if night.dark?
            row(night, visibility)
          else
            row_without_night(night, visibility)
          end
        end
      end
    end
  end

  def filename
    station = @programme.observatory&.code || "coordonnees"

    "skopos-#{station}-#{@programme.week_start.iso8601}.csv"
  end

  private

  def row(night, visibility)
    [
      night.date.iso8601,
      night.dusk.getutc.iso8601,
      night.dawn.getutc.iso8601,
      (visibility.moon_illuminated_fraction * 100).round,
      escape_formula(visibility.target.name),
      visibility.target.magnitude,
      visibility.time_above_low_altitude.in_minutes.round,
      visibility.time_above_high_altitude.in_minutes.round,
      visibility.highest_altitude.degrees.round(1),
      visibility.highest_at.getutc.iso8601,
      visibility.minimum_airmass&.value&.round(2),
      visibility.moon_separation.degrees.round,
      visibility.moon_altitude.degrees.round,
      I18n.t("programmes.verdicts.#{visibility.assessment}")
    ]
  end

  def row_without_night(night, visibility)
    [
      night.date.iso8601,
      *Array.new(3),
      escape_formula(visibility.target.name),
      visibility.target.magnitude,
      *Array.new(7),
      I18n.t("programmes.verdicts.no_night")
    ]
  end

  def escape_formula(value)
    FORMULA_START.match?(value) ? "'#{value}" : value
  end
end
