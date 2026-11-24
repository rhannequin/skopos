# frozen_string_literal: true

class Programme
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization

  MAXIMUM_TARGETS = 20
  MAXIMUM_TARGETS_TEXT_LENGTH = 2_000
  DAYS_PER_WEEK = 7
  LATITUDES = -90..90
  LONGITUDES = -180..360

  attribute_method_suffix "_before_type_cast", parameters: false

  attribute :observatory_code, :string
  attribute :latitude, :float
  attribute :longitude, :float
  attribute :elevation, :float
  attribute :aperture, :integer
  attribute :limiting_magnitude, :float
  attribute :week_start, :date, default: -> { next_monday }
  attribute :targets_text, :string

  normalizes :observatory_code, with: -> { it.strip.upcase }

  validates :limiting_magnitude, presence: true, numericality: true
  validates :targets_text,
    presence: true,
    length: {maximum: MAXIMUM_TARGETS_TEXT_LENGTH}
  validates :aperture,
    numericality: {only_integer: true, greater_than: 0},
    allow_blank: true
  validates :latitude,
    numericality: {
      greater_than_or_equal_to: LATITUDES.begin,
      less_than_or_equal_to: LATITUDES.end
    },
    allow_blank: true
  validates :longitude,
    numericality: {
      greater_than_or_equal_to: LONGITUDES.begin,
      less_than_or_equal_to: LONGITUDES.end
    },
    allow_blank: true
  validates :elevation, numericality: true, allow_blank: true
  validates :week_start, presence: true
  validate :week_within_ephemeris
  validate :station_is_known
  validate :targets_are_readable

  %i[latitude longitude elevation limiting_magnitude].each do |name|
    define_method(:"#{name}=") do |value|
      super(value.is_a?(String) ? value.strip.tr(",", ".") : value)
    end
  end

  def self.next_monday
    Date.current.next_occurring(:monday)
  end

  def observer
    @observer ||= if observatory_code.present?
      observatory&.observer
    else
      Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(latitude),
        longitude: Astronoby::Angle.from_degrees(longitude),
        elevation: Astronoby::Distance.from_meters(elevation.to_f)
      )
    end
  end

  def observatory
    return if observatory_code.blank?

    @observatory ||= Observatory.find_by(code: observatory_code)
  end

  def targets
    target_list.targets
  end

  def nights
    @nights ||= DAYS_PER_WEEK.times.map do |day|
      Night.for(week_start + day, observer: observer)
    end
  end

  def visibilities(night)
    targets.map do |target|
      Visibility.new(
        target: target,
        night: night,
        observer: observer,
        limiting_magnitude: limiting_magnitude
      )
    end
  end

  private

  def attribute_before_type_cast(name)
    @attributes[name].value_before_type_cast
  end

  def target_list
    @target_list ||= Target::List.new(targets_text)
  end

  def week_within_ephemeris
    return if week_start.nil?

    coverage = Ephemeris.coverage
    last_start = coverage.end - DAYS_PER_WEEK
    return if week_start.between?(coverage.begin, last_start)

    errors.add(
      :week_start,
      :outside_ephemeris,
      first: coverage.begin.year,
      last: last_start.year
    )
  end

  def station_is_known
    if observatory_code.present?
      errors.add(:observatory_code, :unknown) unless observatory
    elsif latitude.nil? || longitude.nil?
      errors.add(:base, :station_missing)
    end
  end

  def targets_are_readable
    return if targets_text.blank?
    return if targets_text.length > MAXIMUM_TARGETS_TEXT_LENGTH

    if target_list.invalid_lines.any?
      errors.add(
        :targets_text,
        :unreadable_lines,
        lines: target_list.invalid_lines.to_sentence
      )
    elsif targets.size > MAXIMUM_TARGETS
      errors.add(:targets_text, :too_many, count: MAXIMUM_TARGETS)
    end
  end
end
