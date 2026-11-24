# frozen_string_literal: true

require "rails_helper"

RSpec.describe Night, type: :model do
  describe ".for" do
    it "finds the astronomical dusk and dawn at the OHP" do
      night = Night.for(Date.new(2026, 11, 23), observer: ohp_observer)

      expect(night.dusk).to eq(Time.utc(2026, 11, 23, 17, 46, 15))
      expect(night.dawn).to eq(Time.utc(2026, 11, 24, 5, 1, 26))
    end

    it "finds the night of the given evening far from Greenwich" do
      observer = Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(19.8207),
        longitude: Astronoby::Angle.from_degrees(-155.4681),
        elevation: Astronoby::Distance.from_meters(4205)
      )

      night = Night.for(Date.new(2026, 11, 23), observer: observer)

      expect(night.dusk).to eq(Time.utc(2026, 11, 24, 4, 58, 17))
      expect(night.dawn).to eq(Time.utc(2026, 11, 24, 15, 18, 52))
    end

    it "finds the same night with a longitude counted eastward up to 360°" do
      observer = Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(19.8207),
        longitude: Astronoby::Angle.from_degrees(204.5319),
        elevation: Astronoby::Distance.from_meters(4205)
      )

      night = Night.for(Date.new(2026, 11, 23), observer: observer)

      expect(night.dusk).to eq(Time.utc(2026, 11, 24, 4, 58, 17))
      expect(night.dawn).to eq(Time.utc(2026, 11, 24, 15, 18, 52))
    end

    it "has no astronomical night in June at 52° N" do
      observer = Astronoby::Observer.new(
        latitude: Astronoby::Angle.from_degrees(52),
        longitude: Astronoby::Angle.from_degrees(0)
      )

      night = Night.for(Date.new(2026, 6, 21), observer: observer)

      expect(night).not_to be_dark
    end
  end

  describe "#duration" do
    it "is the time between dusk and dawn" do
      night = Night.new(
        date: Date.new(2026, 11, 23),
        dusk: Time.utc(2026, 11, 23, 17, 46, 15),
        dawn: Time.utc(2026, 11, 24, 5, 1, 26)
      )

      expect(night.duration).to eq(40_511.seconds)
    end

    it "is zero without an astronomical night" do
      night = Night.new(date: Date.new(2026, 6, 21), dusk: nil, dawn: nil)

      expect(night.duration).to eq(0.seconds)
    end
  end
end
