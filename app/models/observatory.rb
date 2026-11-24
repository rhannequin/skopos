# frozen_string_literal: true

class Observatory < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, :longitude, :parallax_cos, :parallax_sin, presence: true

  def observer
    geodetic_coordinates =
      Astronoby::Coordinates::Geodetic.from_ecef(earth_fixed_position)

    Astronoby::Observer.new(
      latitude: geodetic_coordinates.latitude,
      longitude: geodetic_coordinates.longitude,
      elevation: geodetic_coordinates.elevation
    )
  end

  private

  def earth_fixed_position
    earth_radius = Astronoby::Constants::WGS84_EARTH_EQUATORIAL_RADIUS_IN_METERS
    angle = Astronoby::Angle.from_degrees(longitude)
    equatorial_distance = earth_radius * parallax_cos

    Astronoby::Vector[
      Astronoby::Distance.from_meters(equatorial_distance * angle.cos),
      Astronoby::Distance.from_meters(equatorial_distance * angle.sin),
      Astronoby::Distance.from_meters(earth_radius * parallax_sin)
    ]
  end
end
