# frozen_string_literal: true

module Observers
  def ohp_observer
    Astronoby::Observer.new(
      latitude: Astronoby::Angle.from_degrees(43.93187),
      longitude: Astronoby::Angle.from_degrees(5.7157),
      elevation: Astronoby::Distance.from_meters(634)
    )
  end
end

RSpec.configure do |config|
  config.include Observers
end
