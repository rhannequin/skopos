# frozen_string_literal: true

namespace :observatories do
  desc "Import the observatory codes from the Minor Planet Center"
  task import: :environment do
    Observatory::MpcImport.fetch
    puts "#{Observatory.count} observatories"
  end

  desc "Import the observatory codes from the MPC if none is stored yet"
  task import_if_empty: :environment do
    Observatory::MpcImport.fetch_if_empty
  end
end
