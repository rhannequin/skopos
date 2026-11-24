# frozen_string_literal: true

class Target::List
  SEPARATOR = /[\t,;]/
  SEPARATED_FIELDS = 3..4
  MINUS_SIGNS = "\u2212\u2013"
  SEXAGESIMAL = /
    \A(?<sign>[+-]?)
    (?<units>\d+):(?<minutes>\d+):(?<seconds>\d+(?:\.\d+)?)\z
  /x
  DECIMAL = /\A[+-]?\d+(?:\.\d+)?\z/
  HOURS = 0...Astronoby::Constants::HOURS_PER_DAY
  DEGREES = 0...Astronoby::Constants::DEGREES_PER_CIRCLE
  MINUTES = 0...Astronoby::Constants::MINUTES_PER_HOUR
  SECONDS = 0...Astronoby::Constants::SECONDS_PER_MINUTE

  attr_reader :targets, :invalid_lines

  def initialize(text)
    @targets = []
    @invalid_lines = []

    text.to_s.each_line.with_index(1) do |line, number|
      next if line.strip.empty?

      target = parse(line.strip.tr(MINUS_SIGNS, "-"))
      target&.valid? ? @targets << target : @invalid_lines << number
    end
  end

  private

  def parse(line)
    name, right_ascension, declination, magnitude =
      SEPARATOR.match?(line) ? separated_fields(line) : whitespace_fields(line)
    return if magnitude && !DECIMAL.match?(magnitude)

    Target.new(
      name: name.presence,
      right_ascension: right_ascension(right_ascension),
      declination: declination(declination),
      magnitude: magnitude && Float(magnitude)
    )
  end

  def separated_fields(line)
    fields = line.split(SEPARATOR).map(&:strip)
    fields if SEPARATED_FIELDS.cover?(fields.size)
  end

  def whitespace_fields(line)
    tokens = line.split
    magnitude = tokens.pop unless SEXAGESIMAL.match?(tokens.last)
    declination, right_ascension = tokens.pop, tokens.pop
    coordinates = [right_ascension, declination]
    return unless coordinates.all? { SEXAGESIMAL.match?(it.to_s) }

    [tokens.join(" "), right_ascension, declination, magnitude]
  end

  def right_ascension(text)
    if (match = SEXAGESIMAL.match(text.to_s))
      hours, minutes, seconds = sexagesimal_parts(match)
      return unless match[:sign].empty? && HOURS.cover?(hours)
      return unless minutes && seconds

      Astronoby::Angle.from_hms(hours, minutes, seconds)
    elsif DECIMAL.match?(text.to_s) && DEGREES.cover?(Float(text))
      Astronoby::Angle.from_degrees(Float(text))
    end
  end

  def declination(text)
    if (match = SEXAGESIMAL.match(text.to_s))
      degrees, minutes, seconds = sexagesimal_parts(match)
      return unless minutes && seconds

      angle = Astronoby::Angle.from_dms(degrees, minutes, seconds)
      (match[:sign] == "-") ? -angle : angle
    elsif DECIMAL.match?(text.to_s)
      Astronoby::Angle.from_degrees(Float(text))
    end
  end

  def sexagesimal_parts(match)
    minutes = match[:minutes].to_f
    seconds = match[:seconds].to_f

    [
      match[:units].to_f,
      (minutes if MINUTES.cover?(minutes)),
      (seconds if SECONDS.cover?(seconds))
    ]
  end
end
