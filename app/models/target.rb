# frozen_string_literal: true

class Target
  include ActiveModel::Model

  DECLINATIONS =
    Astronoby::Angle.from_degrees(-90)..Astronoby::Angle.from_degrees(90)

  attr_accessor :name, :right_ascension, :declination, :magnitude

  validates :name, :right_ascension, :declination, presence: true
  validates :magnitude, numericality: true, allow_nil: true
  validate :declination_on_the_sky

  def body
    Astronoby::DeepSkyObject.new(
      equatorial_coordinates: Astronoby::Coordinates::Equatorial.new(
        right_ascension: right_ascension,
        declination: declination,
        epoch: Astronoby::JulianDate::J2000
      )
    )
  end

  private

  def declination_on_the_sky
    if declination && !DECLINATIONS.cover?(declination)
      errors.add(:declination, :invalid)
    end
  end
end
