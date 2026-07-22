# frozen_string_literal: true

FactoryBot.define do
  factory :profile do
    name { "Ada Lovelace" }
    email { "ada@example.com" }
    avatar { Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png") }
    bio { "Mathematician and writer." }
    active { true }
    born_on { Date.new(1815, 12, 10) }
    age { 36 }
    status { :published }
    country { "United Kingdom" }
    description { "Wrote the first algorithm." }
  end
end
