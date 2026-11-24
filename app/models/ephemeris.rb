# frozen_string_literal: true

module Ephemeris
  NAME = "inpop21a.bsp"
  LOCK = Mutex.new

  def self.path
    Rails.root.join("storage/ephemerides", NAME)
  end

  def self.current
    LOCK.synchronize { @current ||= Astronoby::Ephem.load(path.to_s) }
  end

  def self.download
    return if path.exist?

    path.dirname.mkpath
    Astronoby::Ephem.download(name: NAME, target: path.to_s)
  end
end
