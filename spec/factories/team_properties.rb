FactoryGirl.define do
  factory :team_property do
    team_id       33
    key           'area'
    value         'Hammersmith'

    trait :area

    trait :lead do
      key         'lead'
      value       'Donald Trump'
    end

    trait :can_allocate_foi do
      key         'can_allocate'
      value       'FOI'
    end

    trait :can_allocate_gq do
      key         'can_allocate'
      value       'GQ'
    end
  end
end