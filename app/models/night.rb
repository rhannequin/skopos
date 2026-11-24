# frozen_string_literal: true

class Night
  HOURS_PER_DAY = Astronoby::Constants::HOURS_PER_DAY
  HALF_DAY_IN_HOURS = HOURS_PER_DAY / 2

  attr_reader :date, :dusk, :dawn

  def self.for(date, observer:, ephem: Ephemeris.current)
    local_mean_noon = Time.utc(date.year, date.month, date.day) +
      (HALF_DAY_IN_HOURS - solar_time_offset(observer.longitude)).hours
    events = Astronoby::TwilightCalculator
      .new(observer: observer, ephem: ephem)
      .events_between(local_mean_noon, local_mean_noon + 1.day)

    new(
      date: date,
      dusk: events.evening_astronomical_twilight_times.first,
      dawn: events.morning_astronomical_twilight_times.first
    )
  end

  def self.solar_time_offset(longitude)
    hours = longitude.hours % HOURS_PER_DAY
    (hours > HALF_DAY_IN_HOURS) ? hours - HOURS_PER_DAY : hours
  end
  private_class_method :solar_time_offset

  def initialize(date:, dusk:, dawn:)
    @date = date
    @dusk = dusk
    @dawn = dawn
  end

  def dark?
    dusk.present? && dawn.present?
  end

  def duration
    dark? ? (dawn - dusk).seconds : 0.seconds
  end
end
