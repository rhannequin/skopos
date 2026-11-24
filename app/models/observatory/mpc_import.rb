# frozen_string_literal: true

class Observatory::MpcImport
  class EmptyListError < StandardError; end

  class TruncatedListError < StandardError; end

  MINIMUM_SHARE_OF_STORED = 0.9

  URL = "https://minorplanetcenter.net/iau/lists/ObsCodes.html"
  LINE = /
    \A(?<code>[0-9A-Z]{3})[ ]
    (?<longitude>.{9})(?<cos>.{8})(?<sin>.{9})(?<name>.+)\z
  /x

  def self.fetch
    require "net/http"

    response = Net::HTTP.get_response(URI(URL))
    response.value
    new(response.body.dup.force_encoding(Encoding::UTF_8)).import
  end

  def initialize(list)
    @list = list
  end

  def import
    observatories = rows
    if observatories.empty?
      raise EmptyListError, "No observatory found in the MPC list"
    end

    if observatories.size < Observatory.count * MINIMUM_SHARE_OF_STORED
      raise TruncatedListError,
        "The MPC list has #{observatories.size} observatories, " \
        "far fewer than the #{Observatory.count} stored"
    end

    Observatory.transaction do
      Observatory.upsert_all(
        observatories,
        unique_by: :code,
        update_only: %i[name longitude parallax_cos parallax_sin]
      )
      Observatory.where.not(code: observatories.pluck(:code)).delete_all
    end
  end

  private

  def rows
    @list.each_line.filter_map { |line| parse(line.chomp) }
  end

  def parse(line)
    match = LINE.match(line) or return
    cos = Float(match[:cos].strip, exception: false)
    sin = Float(match[:sin].strip, exception: false)
    return unless ground_based?(cos, sin)

    {
      code: match[:code],
      name: match[:name].strip,
      longitude: Float(match[:longitude]),
      parallax_cos: cos,
      parallax_sin: sin
    }
  end

  def ground_based?(cos, sin)
    cos && sin && !(cos.zero? && sin.zero?)
  end
end
