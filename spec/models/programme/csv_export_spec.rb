# frozen_string_literal: true

require "rails_helper"

RSpec.describe Programme::CsvExport, type: :model do
  describe "#to_csv" do
    it "has one row per night and target, with French headers" do
      rows = CSV.parse(Programme::CsvExport.new(ohp_programme).to_csv)

      expect(rows.first).to eq(I18n.t("programmes.csv.headers"))
      expect(rows.size).to eq(1 + 7)
    end

    it "gives the figures of a target for a night" do
      rows = CSV.parse(
        Programme::CsvExport.new(ohp_programme).to_csv,
        headers: true
      )

      row = rows.first.to_h.values

      expect(row).to eq([
        "2026-11-23",
        "2026-11-23T17:46:15Z",
        "2026-11-24T05:01:26Z",
        "99",
        "Betelgeuse",
        "0.5",
        "496",
        "438",
        "53.5",
        "2026-11-24T01:21:42Z",
        "1.24",
        "41",
        "52",
        "faisable"
      ])
    end
  end

  describe "rows that differ" do
    it "marks a target that stays low and leaves the airmass empty" do
      row = first_row("Southern 05:00:00 -60:00:00 10")

      expect(row["airmass_min"]).to be_nil
      expect(row["verdict"]).to eq("trop basse")
    end

    it "marks a target without magnitude" do
      row = first_row("Betelgeuse 05:55:10.30536 +07:24:25.4304")

      expect(row["magnitude"]).to be_nil
      expect(row["verdict"]).to eq("magnitude inconnue")
    end

    it "escapes a name that a spreadsheet would run as a formula" do
      row = first_row("=HYPERLINK(1) 05:55:10.30536 +07:24:25.4304 0.5")

      expect(row["cible"]).to eq("'=HYPERLINK(1)")
    end

    it "keeps the nights without astronomical darkness" do
      programme = Programme.new(
        latitude: 52,
        longitude: 0,
        limiting_magnitude: 13.5,
        week_start: Date.new(2026, 6, 15),
        targets_text: "Betelgeuse 05:55:10.30536 +07:24:25.4304 0.5"
      )

      rows = CSV.parse(
        Programme::CsvExport.new(programme).to_csv,
        headers: true
      )

      expect(rows.size).to eq(7)
      expect(rows.first["crepuscule_ut"]).to be_nil
      expect(rows.first["verdict"]).to eq("pas de nuit astronomique")
    end
  end

  def first_row(targets_text)
    programme = ohp_programme
    programme.targets_text = targets_text

    CSV.parse(Programme::CsvExport.new(programme).to_csv, headers: true)
      .first
  end

  def ohp_programme
    create(
      :observatory,
      code: "511",
      longitude: 5.7157,
      parallax_cos: 0.72140,
      parallax_sin: 0.69034
    )

    Programme.new(
      observatory_code: "511",
      limiting_magnitude: 13.5,
      week_start: Date.new(2026, 11, 23),
      targets_text: "Betelgeuse 05:55:10.30536 +07:24:25.4304 0.5"
    )
  end
end
