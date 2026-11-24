# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programme, type: :model do
  describe "validations" do
    it { expect(Programme.new).to validate_presence_of(:limiting_magnitude) }
    it { expect(Programme.new).to validate_presence_of(:targets_text) }

    it "accepts an observatory picked by its MPC code" do
      create(:observatory, code: "511")

      expect(build_programme(observatory_code: "511")).to be_valid
    end

    it "ignores spaces and case around the MPC code" do
      create(:observatory, code: "Z84")

      expect(build_programme(observatory_code: " z84 ")).to be_valid
    end

    it "rejects an unknown MPC code" do
      programme = build_programme(observatory_code: "ZZZ")

      expect(programme).not_to be_valid
      expect(programme.errors[:observatory_code]).to be_present
    end

    it "accepts coordinates instead of a code" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        elevation: 650
      )

      expect(programme).to be_valid
    end

    it "needs a code or coordinates" do
      programme = build_programme

      expect(programme).not_to be_valid
      expect(programme.errors[:base]).to be_present
    end

    it "reads decimal numbers written with a comma" do
      programme = build_programme(latitude: "43,93", longitude: "5,71")
      programme.limiting_magnitude = "13,5"

      expect(programme).to be_valid
      expect(programme.limiting_magnitude).to eq(13.5)
      expect(programme.latitude).to eq(43.93)
    end

    it "rejects a limiting magnitude that is not a number" do
      programme = build_programme(latitude: 43.93, longitude: 5.71)
      programme.limiting_magnitude = "faint"

      expect(programme).not_to be_valid
      expect(programme.errors[:limiting_magnitude]).to be_present
    end

    it "rejects a latitude beyond the poles" do
      programme = build_programme(latitude: 91, longitude: 5.71)

      expect(programme).not_to be_valid
      expect(programme.errors[:latitude])
        .to eq(["doit être inférieur(e) ou égal(e) à 90"])
    end

    it "reports the target lines that cannot be read" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        targets_text: "SN 2026a 10:00:00 +10:00:00 15\nnot a target"
      )

      expect(programme).not_to be_valid
      expect(programme.errors[:targets_text].sole).to include("2")
    end

    it "rejects a week outside the ephemeris" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        week_start: Date.new(2250, 1, 5)
      )

      expect(programme).not_to be_valid
      expect(programme.errors[:week_start]).to be_present
    end

    it "rejects a decimal aperture" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        aperture: "203.2"
      )

      expect(programme).not_to be_valid
      expect(programme.errors[:aperture]).to be_present
    end

    it "limits the length of the target list" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        targets_text: "x" * (Programme::MAXIMUM_TARGETS_TEXT_LENGTH + 1)
      )

      expect(programme).not_to be_valid
      expect(programme.errors[:targets_text]).to be_present
    end

    it "limits the number of targets" do
      lines = Array.new(Programme::MAXIMUM_TARGETS + 1) do |index|
        "SN #{index} 10:00:00 +10:00:00 15"
      end

      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        targets_text: lines.join("\n")
      )

      expect(programme).not_to be_valid
      expect(programme.errors[:targets_text]).to be_present
    end
  end

  describe "#week_start" do
    it "defaults to the next Monday" do
      travel_to Date.new(2026, 11, 25) do
        expect(Programme.new.week_start).to eq(Date.new(2026, 11, 30))
      end
    end
  end

  describe "#nights" do
    it "covers the seven nights of the week" do
      programme = build_programme(
        latitude: 43.93187,
        longitude: 5.7157,
        elevation: 634,
        week_start: Date.new(2026, 11, 23)
      )

      expect(programme.nights.map(&:date))
        .to eq((Date.new(2026, 11, 23)..Date.new(2026, 11, 29)).to_a)
      expect(programme.nights.first.dusk)
        .to eq(Time.utc(2026, 11, 23, 17, 46, 15))
    end
  end

  describe "#observer" do
    it "uses the observatory of the MPC code" do
      create(:observatory, code: "007")

      programme = build_programme(observatory_code: "007")

      expect(programme.observer.latitude.degrees.round(4)).to eq(48.8364)
    end

    it "uses the coordinates when no code is given" do
      programme = build_programme(
        latitude: 43.93,
        longitude: 5.71,
        elevation: 650
      )

      expect(programme.observer.latitude.degrees).to eq(43.93)
      expect(programme.observer.elevation.meters).to eq(650)
    end
  end

  describe "#visibilities" do
    it "gives the visibility of every target for a night" do
      programme = build_programme(
        latitude: 43.93187,
        longitude: 5.7157,
        elevation: 634,
        week_start: Date.new(2026, 11, 23)
      )

      visibilities = programme.visibilities(programme.nights.first)

      expect(visibilities.map { it.target.name }).to eq(["Betelgeuse"])
      expect(visibilities.sole.time_above_low_altitude.in_minutes.round)
        .to eq(496)
    end
  end

  def build_programme(**attributes)
    Programme.new(
      limiting_magnitude: 18,
      targets_text: "Betelgeuse 05:55:10.30536 +07:24:25.4304 0.5",
      **attributes
    )
  end
end
