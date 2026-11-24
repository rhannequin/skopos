# frozen_string_literal: true

require "rails_helper"

RSpec.describe Target::List, type: :model do
  describe "#targets" do
    it "reads sexagesimal coordinates and a magnitude" do
      list = Target::List.new("SN 2026abc 03:12:45.6 -05:30:00 17.2")

      target = list.targets.sole

      expect(target.name).to eq("SN 2026abc")
      expect(target.right_ascension.str(:hms, precision: 1))
        .to eq("3h 12m 45.6s")
      expect(target.declination.str(:dms, precision: 0))
        .to eq("-5° 30′ 0″")
      expect(target.magnitude).to eq(17.2)
    end

    it "keeps the sign of a declination between 0° and -1°" do
      list = Target::List.new("AT 2026xyz 10:00:00 -00:30:00 18")

      expect(list.targets.sole.declination.degrees.round(9)).to eq(-0.5)
    end

    it "reads decimal degrees between separators" do
      list = Target::List.new("EP240315a;150.25;+2.5;16.8")

      target = list.targets.sole

      expect(target.right_ascension.degrees.round(9)).to eq(150.25)
      expect(target.declination.degrees.round(9)).to eq(2.5)
    end

    it "reads tab, comma or semicolon separated values" do
      list = Target::List.new(<<~TEXT)
        SN 2026a\t01:00:00\t+10:00:00\t15
        SN 2026b,02:00:00,+20:00:00,16
        SN 2026c;03:00:00;+30:00:00;17
      TEXT

      expect(list.targets.map(&:name))
        .to eq(["SN 2026a", "SN 2026b", "SN 2026c"])
    end

    it "accepts a target without magnitude" do
      list = Target::List.new("GRB 261124A 05:00:00 +45:00:00")

      expect(list.targets.sole.magnitude).to be_nil
    end

    it "keeps a name ending with a number" do
      list = Target::List.new("Abell 85 00:41:50 -09:18:11 13.5")

      target = list.targets.sole

      expect(target.name).to eq("Abell 85")
      expect(target.right_ascension.hours.round(6)).to eq(0.697222)
    end

    it "reads the Unicode minus sign" do
      list = Target::List.new("SN 2026g 10:00:00 \u221210:00:00 15")

      expect(list.targets.sole.declination.degrees.round(9)).to eq(-10)
    end

    it "skips blank lines" do
      list = Target::List.new("\nSN 2026abc 03:12:45.6 -05:30:00 17.2\n\n")

      expect(list.targets.size).to eq(1)
    end
  end

  describe "#invalid_lines" do
    it "rejects whitespace separated decimal degrees, which are ambiguous" do
      list = Target::List.new("Abell 85 10.46 -9.30")

      expect(list.targets).to be_empty
      expect(list.invalid_lines).to eq([1])
    end

    it "rejects space separated sexagesimal coordinates" do
      list = Target::List.new("SN x 10 00 00 +10 00 00 15")

      expect(list.invalid_lines).to eq([1])
    end

    it "rejects a magnitude that is not a number" do
      list = Target::List.new("SN 2026a,10:00:00,+10:00:00,bright")

      expect(list.invalid_lines).to eq([1])
    end

    it "rejects extra separated fields" do
      list = Target::List.new("SN 2026a,10:00:00,+10:00:00,15,extra")

      expect(list.invalid_lines).to eq([1])
    end

    it "lists the line numbers that cannot be read" do
      list = Target::List.new(<<~TEXT)
        SN 2026abc 03:12:45.6 -05:30:00 17.2
        not a target
        SN 2026def 25:00:00 +95:00:00 16
      TEXT

      expect(list.targets.size).to eq(1)
      expect(list.invalid_lines).to eq([2, 3])
    end

    it "rejects coordinates out of range" do
      list = Target::List.new(<<~TEXT)
        SN 2026a 24:00:00 +10:00:00 15
        SN 2026b 10:60:00 +10:00:00 15
        SN 2026c 10:00:00 +10:00:60 15
        SN 2026d 360 +10 15
        SN 2026e 10:00:00 -91:00:00 15
      TEXT

      expect(list.targets).to be_empty
      expect(list.invalid_lines).to eq([1, 2, 3, 4, 5])
    end
  end
end
