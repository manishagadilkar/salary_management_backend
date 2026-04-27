FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_short_password do
      password { '123' }
      password_confirmation { '123' }
    end

    trait :with_duplicate_email do
      email { create(:user).email }
    end
  end
end
