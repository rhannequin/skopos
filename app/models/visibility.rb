# frozen_string_literal: true

class Visibility
  LOW_ALTITUDE = Astronoby::Angle.from_degrees(20)
  HIGH_ALTITUDE = Astronoby::Angle.from_degrees(30)
  MAGNITUDE_MARGIN = 1

  attr_reader :target, :night

  def initialize(
    target:,
    night:,
    observer:,
    limiting_magnitude:,
    ephem: Ephemeris.current
  )
    @target = target
    @night = night
    @observer = observer
    @limiting_magnitude = limiting_magnitude
    @ephem = ephem
  end

  def time_above_low_altitude
    time_above.fetch(LOW_ALTITUDE)
  end

  def time_above_high_altitude
    time_above.fetch(HIGH_ALTITUDE)
  end

  def observable?
    time_above_low_altitude.positive?
  end

  def highest_altitude
    highest&.altitude
  end

  def highest_at
    highest&.instant&.to_time&.round
  end

  def minimum_airmass
    return unless highest

    Astronoby::Airmass.from_true_altitude(highest.altitude, observer: @observer)
  end

  def moon_illuminated_fraction
    return unless night.dark?

    middle_of_night = night.dusk + night.duration / 2
    instant = Astronoby::Instant.from_time(middle_of_night)

    Astronoby::Moon
      .new(ephem: @ephem, instant: instant)
      .illuminated_fraction
  end

  def moon_separation
    return unless highest

    target_position
      .observed_by(@observer)
      .separation_from(moon_seen_from_station)
  end

  def moon_altitude
    highest && moon_seen_from_station.horizontal.altitude
  end

  def verdict
    return :unknown if target.magnitude.nil? || @limiting_magnitude.nil?

    if target.magnitude <= @limiting_magnitude - MAGNITUDE_MARGIN
      :feasible
    elsif target.magnitude <= @limiting_magnitude
      :marginal
    else
      :out_of_reach
    end
  end

  private

  def time_above
    @time_above ||= if night.dark?
      altitudes = [LOW_ALTITUDE, HIGH_ALTITUDE]
      crossings = crossing_calculator.multiple_crossings_between(
        night.dusk,
        night.dawn,
        altitudes: altitudes
      )
      altitudes.zip(crossings).to_h do |altitude, altitude_crossings|
        [altitude, duration_above(altitude, altitude_crossings)]
      end
    else
      {LOW_ALTITUDE => 0.seconds, HIGH_ALTITUDE => 0.seconds}
    end
  end

  def duration_above(altitude, crossings)
    above_since = night.dusk if altitude_at_dusk > altitude
    total = 0.seconds

    crossings.each do |crossing|
      time = crossing.instant.to_time

      if crossing.direction == :rising
        above_since = time
      else
        total += (time - (above_since || night.dusk)).seconds
        above_since = nil
      end
    end

    above_since ? total + (night.dawn - above_since).seconds : total
  end

  def highest
    return unless night.dark?

    @highest ||= begin
      culminations = crossing_calculator
        .extremes_between(night.dusk, night.dawn)
        .select { it.kind == Astronoby::AltitudeExtreme::UPPER_CULMINATION }
      edges = [
        edge_of_night(night.dusk, altitude_at_dusk),
        edge_of_night(night.dawn, altitude_at(night.dawn))
      ]

      (culminations + edges).max_by(&:altitude)
    end
  end

  def edge_of_night(time, altitude)
    Astronoby::AltitudeExtreme.new(
      kind: Astronoby::AltitudeExtreme::UPPER_CULMINATION,
      instant: Astronoby::Instant.from_time(time),
      altitude: altitude
    )
  end

  def altitude_at_dusk
    @altitude_at_dusk ||= altitude_at(night.dusk)
  end

  def altitude_at(time)
    body
      .at(Astronoby::Instant.from_time(time), ephem: @ephem)
      .observed_by(@observer)
      .horizontal
      .altitude
  end

  def target_position
    body.at(highest.instant, ephem: @ephem)
  end

  def moon_seen_from_station
    @moon_seen_from_station ||= Astronoby::Moon
      .new(ephem: @ephem, instant: highest.instant)
      .observed_by(@observer)
  end

  def body
    @body ||= target.body
  end

  def crossing_calculator
    @crossing_calculator ||= Astronoby::AltitudeCrossingCalculator.new(
      body: body,
      observer: @observer,
      ephem: @ephem
    )
  end
end
