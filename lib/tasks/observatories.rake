# frozen_string_literal: true

namespace :observatories do
  desc "Import the observatory codes from the Minor Planet Center"
  task import: :environment do
    Observatory::MpcImport.fetch
    puts "#{Observatory.count} observatories"
  end
end
