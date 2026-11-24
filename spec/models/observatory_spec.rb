# frozen_string_literal: true

require "rails_helper"

RSpec.describe Observatory, type: :model do
  describe "validations" do
    it { expect(build(:observatory)).to validate_presence_of(:code) }
    it { expect(build(:observatory)).to validate_uniqueness_of(:code) }
    it { expect(build(:observatory)).to validate_presence_of(:name) }
    it { expect(build(:observatory)).to validate_presence_of(:longitude) }
    it { expect(build(:observatory)).to validate_presence_of(:parallax_cos) }
    it { expect(build(:observatory)).to validate_presence_of(:parallax_sin) }
  end

  describe "#observer" do
    it "places the observer from the MPC parallax constants" do
      observatory = build(
        :observatory,
        longitude: 2.33675,
        parallax_cos: 0.65947,
        parallax_sin: 0.749223
      )

      observer = observatory.observer

      expect(observer.latitude.degrees.round(4)).to eq(48.8364)
      expect(observer.longitude.degrees.round(5)).to eq(2.33675)
      expect(observer.elevation.meters.round).to eq(60)
    end

    it "follows a change of position" do
      observatory = build(:observatory)
      observatory.observer

      observatory.longitude = 5.7157

      expect(observatory.observer.longitude.degrees.round(4)).to eq(5.7157)
    end

    it "uses western longitudes for sites west of Greenwich" do
      observatory = build(
        :observatory,
        longitude: 357.45184,
        parallax_cos: 0.79753,
        parallax_sin: 0.60183
      )

      expect(observatory.observer.longitude.degrees.round(5)).to eq(-2.54816)
    end
  end
end
