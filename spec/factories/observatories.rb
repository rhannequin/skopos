# frozen_string_literal: true

FactoryBot.define do
  factory :observatory do
    sequence(:code) { |n| format("Z%02d", n % 100) }
    name { "Paris" }
    longitude { 2.33675 }
    parallax_cos { 0.65947 }
    parallax_sin { 0.749223 }
  end
end
