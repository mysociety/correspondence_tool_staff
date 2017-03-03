# == Schema Information
#
# Table name: case_closure_metadata
#
#  id           :integer          not null, primary key
#  type         :string
#  subtype      :string
#  name         :string
#  abbreviation :string
#  sequence_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryGirl.define do
  factory :exemption, class: CaseClosure::Exemption do
    sequence(:subtype) { |n| "subtype_#{n}" }
    sequence(:name) { |n| "Exemption #{n}" }
    sequence(:abbreviation) { |n| "abbrev-#{n}" }
    sequence(:sequence_id) { |n| 500 + n }

    trait :ncnd do
      subtype 'ncnd'
    end

    trait :absolute do
      subtype 'absolute'
    end

    trait :qualified do
      subtype 'qualified'
    end

    factory :outcome, class: CaseClosure::Outcome do
      subtype nil
      sequence(:name) { |n| "Outcome #{n}" }
      sequence(:sequence_id) { |n| n }
    end
  end


end