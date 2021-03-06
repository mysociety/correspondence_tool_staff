# == Schema Information
#
# Table name: feedback
#
#  id         :integer          not null, primary key
#  content    :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Feedback, type: :model do

  let(:feedback) { build :feedback}

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(feedback).to be_valid
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:comment) }
    it { should validate_presence_of(:email)   }
  end

end
