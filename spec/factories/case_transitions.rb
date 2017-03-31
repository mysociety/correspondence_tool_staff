# == Schema Information
#
# Table name: case_transitions
#
#  id          :integer          not null, primary key
#  event       :string
#  to_state    :string           not null
#  metadata    :jsonb
#  sort_key    :integer          not null
#  case_id     :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryGirl.define do
  factory :case_transition do
    association :case
    sort_key do
      last_sort_key =
        CaseTransition.where(case_id: case_id).order(:sort_key).last&.sort_key || 0
      last_sort_key + 10
    end
    most_recent true

    before(:create) do |transition|
      CaseTransition.where(case_id: transition.case_id).update(most_recent: false)
    end
  end

  factory :case_transition_assign_responder, parent: :case_transition do
    transient do
      manager         { create :manager }
      managing_team   { manager.managing_teams.first }
      responding_team { create :responding_team }
    end

    to_state           'awaiting_responder'
    event              'assign_responder'
    user_id            { manager.id }
    managing_team_id   { managing_team.id }
    responding_team_id { responding_team.id }
  end

  factory :case_transition_accept_responder_assignment, parent: :case_transition do
    to_state 'drafting'
    event 'accept_responder_assignment'
  end

  factory :case_transition_add_responses, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'awaiting_dispatch'
    user_id            { responder.id }
    responding_team_id { responding_team.id }
    filenames          ['file1.pdf', 'file2.pdf']
    event 'add_responses'
  end

  factory :case_transition_respond, parent: :case_transition do
    transient do
      responder       { create :responder }
      responding_team { responder.responding_teams.first }
    end

    to_state 'responded'
    event 'respond'
    user_id            { responder.id }
    responding_team_id { responding_team.id }
  end

  factory :case_transition_close, parent: :case_transition do
    to_state 'closed'
    event 'close'
  end
end
