require 'rails_helper'

describe SearchQueryDecorator, type: :model do

  let(:manager) { create(:manager) }
  let(:query) { create(:search_query, user_id: manager.id) }

  subject { SearchQueryDecorator.decorate(query) }

  it 'should display the user roles' do
    expect(subject.user_roles).to eq 'manager'
  end

  it 'should display the user name' do
    expect(subject.user_name).to eq manager.full_name
  end

  it 'should display the query details' do
    expect(subject.query_details).to eq 'search text: Winne the Pooh'
  end
end
