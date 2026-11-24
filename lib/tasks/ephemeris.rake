# frozen_string_literal: true

namespace :ephemeris do
  desc "Download the INPOP21a ephemeris from the IMCCE if it is missing"
  task download: :environment do
    Ephemeris.download
  end
end
