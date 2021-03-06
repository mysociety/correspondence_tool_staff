# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#  active                  :boolean          default(TRUE)
#  omit_for_part_refused   :boolean          default(FALSE)
#

require 'rails_helper'

module CaseClosure

  describe InfoHeldStatus do

    before(:all) do
      @held           = create :info_status, :held
      @not_held       = create :info_status, :not_held
      @part_held      = create :info_status, :part_held
      @not_confirmed  = create :info_status, :ncnd
    end

    after(:all) { InfoHeldStatus.delete_all }


    describe 'abbreviation class methods' do
      it 'returns the expected record' do
        expect(InfoHeldStatus.held).to eq @held
        expect(InfoHeldStatus.not_held).to eq @not_held
        expect(InfoHeldStatus.part_held).to eq @part_held
        expect(InfoHeldStatus.not_confirmed).to eq @not_confirmed
      end
    end

    describe '.id_from_abbreviation' do
      context 'passed nil as a aprameter' do
        it 'returns nil' do
          expect(InfoHeldStatus.id_from_abbreviation(nil)).to be_nil
        end
      end

      context 'passed a valid abbreviation' do
        it 'returns the correct record' do
          expect(InfoHeldStatus.id_from_abbreviation('part_held')).to eq @part_held.id
        end
      end

      context 'passed a non-existent abbreviation' do
        it 'raises' do
          expect{
            InfoHeldStatus.id_from_abbreviation('xxx')
          }.to raise_error ActiveRecord::RecordNotFound, "Couldn't find CaseClosure::InfoHeldStatus"
        end
      end
    end
  end
end
