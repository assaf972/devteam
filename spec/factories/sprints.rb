FactoryBot.define do
  factory :sprint do
    name { "MyString" }
    project { nil }
    start_date { "2026-05-22" }
    end_date { "2026-05-22" }
    status { 1 }
    goals { "MyText" }
    velocity { 1 }
  end
end
