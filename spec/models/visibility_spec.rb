# frozen_string_literal: true

require "rails_helper"

RSpec.describe Visibility, type: :model do
  describe "from the OHP on the night of 23 November 2026" do
    it "measures the time Betelgeuse spends above 20° and 30°" do
      visibility = ohp_visibility(betelgeuse)

      expect(visibility.time_above_low_altitude.in_minutes.round).to eq(496)
      expect(visibility.time_above_high_altitude.in_minutes.round).to eq(438)
    end

    it "gives the periods Betelgeuse spends above 20° and 30°" do
      visibility = ohp_visibility(betelgeuse)

      low = visibility.periods_above_low_altitude.sole
      high = visibility.periods_above_high_altitude.sole

      expect(low.begin.strftime("%H:%M")).to eq("20:45")
      expect(low.end).to eq(Time.utc(2026, 11, 24, 5, 1, 26))
      expect(high.begin.strftime("%H:%M")).to eq("21:42")
      expect(high.end).to eq(Time.utc(2026, 11, 24, 5, 0, 45))
      expect(visibility.periods_above_low_altitude).to be_frozen
    end

    it "finds Betelgeuse at its highest when it culminates" do
      visibility = ohp_visibility(betelgeuse)

      expect(visibility.highest_altitude.degrees.round(2)).to eq(53.48)
      expect(visibility.highest_at.strftime("%H:%M")).to eq("01:21")
      expect(visibility.minimum_airmass.value.round(2)).to eq(1.24)
    end

    it "finds Vega at its highest at dusk, as it sets during the night" do
      night = Night.for(Date.new(2026, 11, 23), observer: ohp_observer)
      visibility = ohp_visibility(vega)

      expect(visibility.highest_at).to eq(night.dusk)
      expect(visibility.highest_altitude.degrees.round(1)).to eq(48.8)
    end

    it "gives the Moon phase in the middle of the night" do
      betelgeuse_phase = ohp_visibility(betelgeuse).moon_illuminated_fraction
      vega_phase = ohp_visibility(vega).moon_illuminated_fraction

      expect(betelgeuse_phase.round(2)).to eq(0.99)
      expect(vega_phase).to eq(betelgeuse_phase)
    end

    it "gives the Moon distance and altitude when the target is highest" do
      visibility = ohp_visibility(betelgeuse)

      expect(visibility.moon_separation.degrees.round).to eq(41)
      expect(visibility.moon_altitude.degrees.round).to eq(52)
    end

    it "is observable when the target rises above 20°" do
      expect(ohp_visibility(betelgeuse)).to be_observable
    end

    it "is not observable when the target stays low" do
      target = Target.new(
        name: "Southern",
        right_ascension: Astronoby::Angle.from_hms(5, 0, 0),
        declination: Astronoby::Angle.from_degrees(-60),
        magnitude: 12
      )

      expect(ohp_visibility(target)).not_to be_observable
    end
  end

  describe "without an astronomical night" do
    it "has no time above the altitude limits and no highest point" do
      night = Night.new(date: Date.new(2026, 6, 21), dusk: nil, dawn: nil)

      visibility = Visibility.new(
        target: betelgeuse,
        night: night,
        observer: ohp_observer,
        limiting_magnitude: 18
      )

      expect(visibility.time_above_low_altitude).to eq(0.seconds)
      expect(visibility.time_above_high_altitude).to eq(0.seconds)
      expect(visibility.periods_above_low_altitude).to be_empty
      expect(visibility.highest_altitude).to be_nil
      expect(visibility.minimum_airmass).to be_nil
      expect(visibility.moon_separation).to be_nil
      expect(visibility.moon_illuminated_fraction).to be_nil
      expect(visibility).not_to be_observable
    end
  end

  describe "#verdict" do
    it "is feasible at least one magnitude brighter than the limit" do
      expect(verdict_for(magnitude: 17)).to eq(:feasible)
    end

    it "is marginal within one magnitude of the limit" do
      expect(verdict_for(magnitude: 17.5)).to eq(:marginal)
      expect(verdict_for(magnitude: 18)).to eq(:marginal)
    end

    it "is out of reach beyond the limit" do
      expect(verdict_for(magnitude: 18.1)).to eq(:out_of_reach)
    end

    it "is unknown without a magnitude" do
      expect(verdict_for(magnitude: nil)).to eq(:unknown)
    end

    it "is unknown without a limiting magnitude" do
      verdict = verdict_for(magnitude: 15, limiting_magnitude: nil)

      expect(verdict).to eq(:unknown)
    end
  end

  def ohp_visibility(target)
    Visibility.new(
      target: target,
      night: Night.for(Date.new(2026, 11, 23), observer: ohp_observer),
      observer: ohp_observer,
      limiting_magnitude: 18
    )
  end

  def verdict_for(magnitude:, limiting_magnitude: 18)
    target = Target.new(
      name: "SN",
      right_ascension: betelgeuse.right_ascension,
      declination: betelgeuse.declination,
      magnitude: magnitude
    )
    night = Night.new(date: Date.new(2026, 11, 23), dusk: nil, dawn: nil)

    Visibility.new(
      target: target,
      night: night,
      observer: ohp_observer,
      limiting_magnitude: limiting_magnitude
    ).verdict
  end

  def betelgeuse
    Target.new(
      name: "Betelgeuse",
      right_ascension: Astronoby::Angle.from_hms(5, 55, 10.30536),
      declination: Astronoby::Angle.from_dms(7, 24, 25.4304),
      magnitude: 0.5
    )
  end

  def vega
    Target.new(
      name: "Vega",
      right_ascension: Astronoby::Angle.from_hms(18, 36, 56.33635),
      declination: Astronoby::Angle.from_dms(38, 47, 1.2802),
      magnitude: 0.03
    )
  end
end
