# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

require 'rails_helper'

RSpec.describe BusinessGroup, type: :model do
  it 'can be created' do
    bg = BusinessGroup.create name: 'Group Hugs',
                              email: 'group.hugs@localhost'
    expect(bg).to be_valid
  end

  it { should validate_absence_of(:parent_id) }

  it { should have_many(:directorates).with_foreign_key(:parent_id) }

  it { should have_many(:business_units).through(:directorates)  }
end
