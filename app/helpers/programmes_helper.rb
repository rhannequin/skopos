# frozen_string_literal: true

module ProgrammesHelper
  def format_duration(duration)
    hours, minutes = duration.in_minutes.round.divmod(60)

    if hours.positive?
      t(
        "programmes.duration.hours",
        hours: hours,
        minutes: format("%02d", minutes)
      )
    elsif minutes.positive?
      t("programmes.duration.minutes", minutes: minutes)
    else
      t("programmes.duration.none")
    end
  end

  def format_time(time)
    time.getutc.strftime("%H:%M")
  end

  def format_decimal(value, precision: 1)
    number_with_precision(value, precision: precision)
  end

  def format_magnitude(value)
    number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
  end

  def band_style(period, night)
    left = band_offset(period.begin, night)
    width = band_offset(period.end, night) - left

    "left: #{left.round(1)}%; width: #{width.round(1)}%"
  end

  def band_position(time, night)
    "left: #{band_offset(time, night).round(1)}%"
  end

  def station_label(programme)
    if programme.observatory
      "#{programme.observatory.code} #{programme.observatory.name}"
    else
      coordinates = t(
        "programmes.station.coordinates",
        latitude: format_decimal(programme.latitude, precision: 4),
        longitude: format_decimal(programme.longitude, precision: 4)
      )
      return coordinates if programme.elevation.nil?

      t(
        "programmes.station.elevation",
        coordinates: coordinates,
        elevation: programme.elevation.round
      )
    end
  end

  def verdict(visibility)
    return :too_low unless visibility.observable?

    visibility.verdict
  end

  def instrument_label(programme)
    magnitude = format_magnitude(programme.limiting_magnitude)

    if programme.aperture
      t(
        "programmes.instrument.with_aperture",
        aperture: programme.aperture,
        magnitude: magnitude
      )
    else
      t("programmes.instrument.without_aperture", magnitude: magnitude)
    end
  end

  private

  def band_offset(time, night)
    (time - night.dusk) / night.duration * 100
  end
end
