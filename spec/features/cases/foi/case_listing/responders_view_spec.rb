require 'rails_helper'

feature 'listing cases on the system' do
  given(:foi_category) { create(:category) }
  given(:responder_a) { create :responder,
                               full_name: 'Responder A',
                               responding_teams: [responding_team_a] }
  given(:responder_b) { create :responder,
                               full_name: 'Responder B',
                               responding_teams: [responding_team_b] }
  given(:responding_team_a) { create :responding_team,
                                     name: 'Responding Team A' }
  given(:responding_team_b) { create :responding_team,
                                     name: 'Responding Team B' }
  given(:coresponder_a)     { create :responder,
                                     full_name: 'Co-Responder A',
                                     responding_teams: [responding_team_a] }

  given(:unassigned_case) { create :case  }
  given(:assigned_case_team_a) { create :assigned_case,
                                        responding_team: responding_team_a }
  given(:assigned_case_team_b) { create :assigned_case,
                                        responding_team: responding_team_b }
  given(:accepted_case_team_a) { create :accepted_case,
                                        responder: responder_a }
  given(:accepted_case_team_b) { create :accepted_case,
                                        responder: responder_b }
  given(:rejected_case_team_a) { create :rejected_case,
                                        responder: responder_a }
  given(:rejected_case_team_b) { create :rejected_case,
                                        responder: responder_b }
  given(:case_with_response_team_a) { create :case_with_response,
                                             responder: responder_a }
  given(:case_with_response_team_b) { create :case_with_response,
                                             responder: responder_b }
  given(:responded_case_team_a) { create :responded_case,
                                         responder: responder_a }
  given(:responded_case_team_b) { create :responded_case,
                                         responder: responder_b }
  given(:closed_case_team_a) { create :responded_case,
                                      responder: responder_a }
  given(:closed_case_team_b) { create :responded_case,
                                      responder: responder_b }

  background do
    # Create our cases
    unassigned_case
    assigned_case_team_a
    assigned_case_team_b
    accepted_case_team_a
    accepted_case_team_b
    rejected_case_team_a
    rejected_case_team_b
    case_with_response_team_a
    case_with_response_team_b
    responded_case_team_a
    responded_case_team_b
    closed_case_team_a
    closed_case_team_b
  end

  scenario 'For responders - shows only their assigned and accepted cases' do
    login_as responder_a
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_a)
                             .and_be_with('Responding Team A')
    expect(cases.second).to match_the_case(accepted_case_team_a)
                              .and_be_with('Responder A')
    expect(cases.third).to match_the_case(case_with_response_team_a)
                             .and_be_with('Responder A')
  end

  scenario 'For responder coworkers - shows teams assigned and accepted cases' do
    login_as coresponder_a
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_a)
                             .and_be_with('Responding Team A')
    expect(cases.second).to match_the_case(accepted_case_team_a)
                              .and_be_with('Responder A')
    expect(cases.third).to match_the_case(case_with_response_team_a)
                             .and_be_with('Responder A')
  end

  scenario 'For responders on other teams - shows their cases' do
    login_as responder_b
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_b)
                             .and_be_with('Responding Team B')
    expect(cases.second).to match_the_case(accepted_case_team_b)
                              .and_be_with('Responder B')
    expect(cases.third).to match_the_case(case_with_response_team_b)
                             .and_be_with('Responder B')
  end
end