FactoryBot.define do
    factory :user do
      email { Faker::Internet.email}
      password {'passwprd'}
    end
end