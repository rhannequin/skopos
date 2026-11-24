# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProgrammesHelper, type: :helper do
  describe "#format_duration" do
    it "shows hours and minutes" do
      expect(helper.format_duration(571.minutes)).to eq("9 h 31")
    end

    it "shows minutes alone under an hour" do
      expect(helper.format_duration(20.minutes)).to eq("20 min")
    end

    it "shows nothing for no time at all" do
      expect(helper.format_duration(0.seconds)).to eq("0")
    end
  end

  describe "#format_magnitude" do
    it "keeps up to two decimals with a French separator" do
      expect(helper.format_magnitude(17.25)).to eq("17,25")
      expect(helper.format_magnitude(13.0)).to eq("13")
    end
  end

  describe "#station_label" do
    it "shows the coordinates without an altitude" do
      programme = Programme.new(latitude: 43.93, longitude: 5.71)

      expect(helper.station_label(programme)).to eq("43,9300°, 5,7100°")
    end

    it "adds the altitude when there is one" do
      programme = Programme.new(
        latitude: 43.93,
        longitude: 5.71,
        elevation: 650
      )

      expect(helper.station_label(programme))
        .to eq("43,9300°, 5,7100°, 650 m")
    end
  end

  describe "#instrument_label" do
    it "shows the aperture when there is one" do
      programme = Programme.new(aperture: 300, limiting_magnitude: 13.5)

      expect(helper.instrument_label(programme))
        .to eq("300 mm, magnitude limite 13,5")
    end

    it "shows only the limiting magnitude otherwise" do
      programme = Programme.new(limiting_magnitude: 13.5)

      expect(helper.instrument_label(programme)).to eq("magnitude limite 13,5")
    end
  end

  describe "#format_time" do
    it "shows the UT time without changing the given time" do
      time = Time.new(2026, 11, 23, 18, 46, 15, "+01:00")

      expect(helper.format_time(time)).to eq("17:46")
      expect(time.utc_offset).to eq(3600)
    end
  end

  describe "#band_style" do
    it "places a period on the band of the night" do
      night = Night.new(
        date: Date.new(2026, 11, 23),
        dusk: Time.utc(2026, 11, 23, 18),
        dawn: Time.utc(2026, 11, 24, 6)
      )
      period = Time.utc(2026, 11, 23, 21)..Time.utc(2026, 11, 24, 3)

      expect(helper.band_style(period, night))
        .to eq("left: 25.0%; width: 50.0%")
    end
  end
end
