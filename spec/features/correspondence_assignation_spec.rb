require 'rails_helper'

feature 'Correspondence can be assigned to a drafter' do

  background do
    create(:correspondence)
    create(:user, email: 'jane_doe@drafters-example.com')
  end

  scenario 'from the detail view' do
    login_as create(:user)
    correspondence = Correspondence.first
    visit "correspondence/#{correspondence.id}"
    page.find(:select, text: 'jane_doe@drafters-example.com').select('jane_doe@drafters-example.com')
    click_button 'Assign'
    expect(page).to have_content("Case assigned to #{User.first.email}")
  end
end
