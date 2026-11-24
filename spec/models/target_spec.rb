# frozen_string_literal: true

require "rails_helper"

RSpec.describe Target, type: :model do
  describe "validations" do
    it { expect(build_target).to validate_presence_of(:name) }
    it { expect(build_target).to validate_presence_of(:right_ascension) }
    it { expect(build_target).to validate_presence_of(:declination) }
    it do
      expect(build_target).to validate_numericality_of(:magnitude).allow_nil
    end

    it "accepts a declination at a pole" do
      target = build_target(declination: Astronoby::Angle.from_degrees(-90))

      expect(target).to be_valid
    end

    it "rejects a declination beyond the poles" do
      target = build_target(declination: Astronoby::Angle.from_degrees(91))

      expect(target).not_to be_valid
    end
  end

  describe "#body" do
    it "is a deep-sky object at its J2000 coordinates" do
      target = build_target(
        right_ascension: Astronoby::Angle.from_hms(18, 36, 56.33635),
        declination: Astronoby::Angle.from_dms(38, 47, 1.2802)
      )

      coordinates = target
        .body
        .at(Astronoby::Instant.from_time(Time.utc(2000, 1, 1, 12)))
        .astrometric
        .equatorial

      expect(coordinates.right_ascension.str(:hms, precision: 0))
        .to eq("18h 36m 56s")
      expect(coordinates.declination.str(:dms, precision: 0))
        .to eq("+38° 47′ 1″")
    end
  end

  def build_target(**attributes)
    Target.new(
      name: "Vega",
      right_ascension: Astronoby::Angle.from_hms(18, 36, 56.33635),
      declination: Astronoby::Angle.from_dms(38, 47, 1.2802),
      magnitude: 0.03,
      **attributes
    )
  end
end
