# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ephemeris do
  describe ".path" do
    it "points to the INPOP21a kernel in storage" do
      expect(Ephemeris.path)
        .to eq(Rails.root.join("storage/ephemerides/inpop21a.bsp"))
    end
  end

  describe ".coverage" do
    it "spans the dates covered by every segment of the kernel" do
      expect(Ephemeris.coverage)
        .to eq(Date.new(1897, 6, 30)..Date.new(2102, 7, 4))
    end
  end

  describe ".current" do
    it "loads the kernel once" do
      expect(Ephemeris.current).to be_a(Ephem::SPK)
      expect(Ephemeris.current).to be(Ephemeris.current)
    end
  end
end
