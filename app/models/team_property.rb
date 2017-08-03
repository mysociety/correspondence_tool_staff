# == Schema Information
#
# Table name: team_properties
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  key        :string
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeamProperty < ActiveRecord::Base


  VALID_KEYS = %w(
    area
    lead
    can_allocate
    role
  )

  validates :value, uniqueness: { scope: [:team_id, :key], message: "%{value} is not unique in team and key" }
  validates :key, inclusion: { in: VALID_KEYS, message: "%{value} is not a valid key" }
  validates :value,
            if: -> (tp) { tp.key == 'role' },
            inclusion: ['manager', 'responder', 'approver']

  scope :area, -> { where( key: 'area').order(:value) }
  scope :lead, -> { where( key: 'lead') }
  scope :role, -> { where( key: 'role') }

end
