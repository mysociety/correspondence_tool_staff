require 'rails_helper'

describe CasePolicy do
  subject { described_class }

  let(:managing_team)     { create :team_dacu }
  let(:manager)           { managing_team.managers.first }
  let(:responding_team)   { create :responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:coworker)          { create :responder,
                                   responding_teams: [responding_team] }
  let(:another_responder) { create :responder}
  let(:dacu_disclosure)   { find_or_create :team_dacu_disclosure }
  let(:approver)          { dacu_disclosure.approvers.first }
  let(:co_approver)       { create :approver, approving_team: dacu_disclosure }

  let(:new_case)                { create :case }
  let(:accepted_case)           { create :accepted_case,
                                         responder: responder,
                                         manager: manager }
  let(:flagged_accepted_case)           { create :accepted_case, :flagged,
                                          responder: responder,
                                          manager: manager }
  let(:assigned_case)           { create :assigned_case,
                                    responding_team: responding_team }
  let(:assigned_flagged_case)   { create :assigned_case, :flagged,
                                         approving_team: dacu_disclosure}
  let(:assigned_trigger_case)   { create :assigned_case, :flagged_accepted,
                                         approver: approver }
  let(:rejected_case)           { create :rejected_case,
                                         responding_team: responding_team }
  let(:unassigned_case)         { new_case }
  let(:unassigned_flagged_case) { create :case, :flagged,
                                         approving_team: dacu_disclosure }
  let(:unassigned_trigger_case) { create :case, :flagged_accepted,
                                         approving_team: dacu_disclosure }
  let(:case_with_response)      { create :case_with_response,
                                         responder: responder }
  let(:responded_case)          { create :responded_case,
                                         responder: responder }
  let(:closed_case)             { create :closed_case,
                                         responder: responder }
  let(:pending_dacu_clearance_case) { create :pending_dacu_clearance_case, approver: approver }
  let(:awaiting_dispatch_case)  { create :case_with_response, responding_team: responding_team, responder: responder }
  let(:awaiting_dispatch_flagged_case)  { create :case_with_response, :flagged, responding_team: responding_team, responder: responder }


  permissions :can_view_attachments? do
    context 'flagged cases' do
      it { should permit(manager,            awaiting_dispatch_flagged_case)  }
      it { should permit(responder,          awaiting_dispatch_flagged_case)  }
      it { should permit(another_responder,  awaiting_dispatch_flagged_case)  }
      it { should permit(approver,           awaiting_dispatch_flagged_case)  }
      it { should permit(co_approver,        awaiting_dispatch_flagged_case)  }
    end

    context 'unflagged cases' do
      context 'in awaiting_dispatch state' do
        it { should     permit(responder,         awaiting_dispatch_case) }
        it { should     permit(coworker,          awaiting_dispatch_case) }
        it { should_not permit(manager,           awaiting_dispatch_case) }
        it { should_not permit(approver,          awaiting_dispatch_case) }
      end

      context 'in other states' do
        it { should permit(manager,            responded_case) }
        it { should permit(responder,          responded_case)  }
        it { should permit(another_responder,  responded_case)  }
        it { should permit(approver,           responded_case)  }
        it { should permit(co_approver,        responded_case)  }
      end
    end
  end

  after(:each) do |example|
    if example.exception
      failed_checks = CasePolicy.failed_checks rescue []
      puts "Failed CasePolicy checks: #{failed_checks.map(&:to_s).join(', ')}"
    end
  end

  permissions :can_accept_or_reject_approver_assignment? do
    it { should_not permit(manager,           unassigned_flagged_case) }
    it { should_not permit(responder,         unassigned_flagged_case) }
    it { should_not permit(another_responder, unassigned_flagged_case) }
    it { should     permit(approver,          unassigned_flagged_case) }
    it { should_not permit(approver,          unassigned_trigger_case) }
  end

  permissions :can_unaccept_approval_assignment? do
    it { should     permit(approver,          pending_dacu_clearance_case) }
    it { should_not permit(manager,           pending_dacu_clearance_case) }
    it { should_not permit(responder,         pending_dacu_clearance_case) }
  end

  describe  do
    permissions :can_take_on_for_approval? do
      it { should_not   permit(approver,          pending_dacu_clearance_case) }
      it { should       permit(approver,          flagged_accepted_case) }
      it { should_not   permit(manager,           pending_dacu_clearance_case) }
      it { should_not   permit(responder,         pending_dacu_clearance_case) }
    end
  end

  permissions :can_accept_or_reject_responder_assignment? do
    it { should_not permit(manager,           assigned_case) }
    it { should     permit(responder,         assigned_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(approver,          assigned_case) }
  end

  permissions :can_add_attachment? do
    context 'in drafting state' do
      it { should_not permit(manager,           accepted_case) }
      it { should     permit(responder,         accepted_case) }
      it { should     permit(coworker,          accepted_case) }
      it { should_not permit(another_responder, accepted_case) }
    end

    context 'in awaiting_dispatch state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should_not permit(responder,         flagged_accepted_case) }
        it { should_not permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
      end

      context 'unflagged_case' do

        it { should_not permit(manager,           case_with_response) }
        it { should     permit(responder,         case_with_response) }
        it { should     permit(coworker,          case_with_response) }
        it { should_not permit(another_responder, case_with_response) }
      end
    end
  end

  permissions :can_add_attachment_to_flagged_case? do
    context 'in awiting dispatch_state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should     permit(responder,         flagged_accepted_case) }
        it { should     permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
      end

      context 'unflagged case' do
        it { should_not permit(manager,           accepted_case) }
        it { should_not permit(responder,         accepted_case) }
        it { should_not permit(coworker,          accepted_case) }
        it { should_not permit(another_responder, accepted_case) }
      end
    end
  end

  permissions :can_add_attachment_to_flagged_and_unflagged_cases? do
    context 'in awaiting dispatch_state' do
      context 'flagged case' do
        it { should_not permit(manager,           flagged_accepted_case) }
        it { should     permit(responder,         flagged_accepted_case) }
        it { should     permit(coworker,          flagged_accepted_case) }
        it { should_not permit(another_responder, flagged_accepted_case) }
        it { should_not permit(approver,          flagged_accepted_case) }
      end

      context 'unflagged case' do
        it { should_not permit(manager,           accepted_case) }
        it { should     permit(responder,         accepted_case) }
        it { should     permit(coworker,          accepted_case) }
        it { should_not permit(another_responder, accepted_case) }
        it { should_not permit(approver,          accepted_case) }
      end

      context 'pending clearance case' do
        it { should_not permit(manager,           pending_dacu_clearance_case) }
        it { should_not permit(responder,         pending_dacu_clearance_case) }
        it { should_not permit(coworker,          pending_dacu_clearance_case) }
        it { should_not permit(another_responder, pending_dacu_clearance_case) }
        it { should     permit(approver,          pending_dacu_clearance_case) }
      end
    end
  end

  permissions :can_add_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
  end

  permissions :can_assign_case? do
    it { should_not permit(responder, new_case) }
    it { should     permit(manager,   new_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(responder, assigned_case) }
  end

  permissions :can_close_case? do
    it { should_not permit(responder, responded_case) }
    it { should     permit(manager,   responded_case) }
  end

  permissions :can_flag_for_clearance? do
    it { should_not permit(responder, assigned_case) }
    it { should     permit(manager,   assigned_case) }
    it { should     permit(approver,  assigned_case) }
    it { should_not permit(responder, assigned_flagged_case) }
    it { should_not permit(manager,   assigned_flagged_case) }
    it { should_not permit(approver,  assigned_flagged_case) }
  end

  permissions :can_remove_attachment? do
    context 'case is still being drafted' do
      it { should     permit(responder,         case_with_response) }
      it { should_not permit(another_responder, case_with_response) }
      it { should_not permit(manager,           case_with_response) }
    end

    context 'case has been marked as responded' do
      it { should_not permit(another_responder, responded_case) }
      it { should_not permit(manager,           responded_case) }
    end
  end

  permissions :can_respond? do
    it { should_not permit(manager,           case_with_response) }
    it { should     permit(responder,         case_with_response) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(responder,         accepted_case) }
    it { should_not permit(coworker,          accepted_case) }
  end

  permissions :can_unflag_for_clearance? do
    it { should_not permit(responder, assigned_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(approver,  assigned_case) }
    it { should_not permit(responder, assigned_flagged_case) }
    it { should     permit(manager,   assigned_flagged_case) }
    it { should     permit(approver,  assigned_flagged_case) }
  end

  permissions :can_reassign_approver? do
    context 'unflagged case' do
      it { should_not permit(approver, accepted_case) }
    end

    context 'flagged by not yet taken by approver' do
      it 'does not permit' do
        expect(flagged_accepted_case.requires_clearance?).to be true
        expect(flagged_accepted_case.approvers).to be_empty
        should_not permit(approver, flagged_accepted_case)
      end
    end

    context 'flagged case taken on by the current approver' do
      it 'does not permit' do
        expect(pending_dacu_clearance_case.requires_clearance?).to be true
        expect(pending_dacu_clearance_case.approvers.first)
          .to be_instance_of(User)
        should_not permit(pending_dacu_clearance_case.approvers.first,
                          pending_dacu_clearance_case)
      end
    end

    context 'flagged case taken on by a different approver' do
      it 'permits' do
        expect(pending_dacu_clearance_case.requires_clearance?).to be true
        expect(pending_dacu_clearance_case.approvers.first)
          .to be_instance_of(User)
        expect(co_approver).not_to eq pending_dacu_clearance_case.approvers.first
        should permit(co_approver, pending_dacu_clearance_case)
      end
    end
  end

  permissions :can_approve_case? do
    it { should     permit(pending_dacu_clearance_case.approvers.first,
                           pending_dacu_clearance_case) }
    it { should_not permit(approver,   new_case) }
    it { should_not permit(approver,   accepted_case) }
    it { should_not permit(approver,   assigned_case) }
    it { should_not permit(approver,   rejected_case) }
    it { should_not permit(approver,   unassigned_case) }
    it { should_not permit(approver,   unassigned_flagged_case) }
    it { should_not permit(approver,   unassigned_trigger_case) }
    it { should_not permit(approver,   case_with_response) }
    it { should_not permit(approver,   responded_case) }
    it { should_not permit(approver,   closed_case) }

    it { should_not permit(co_approver,   assigned_trigger_case) }
    it { should_not permit(co_approver,   new_case) }
    it { should_not permit(co_approver,   accepted_case) }
    it { should_not permit(co_approver,   assigned_case) }
    it { should_not permit(co_approver,   rejected_case) }
    it { should_not permit(co_approver,   unassigned_case) }
    it { should_not permit(co_approver,   unassigned_flagged_case) }
    it { should_not permit(co_approver,   unassigned_trigger_case) }
    it { should_not permit(co_approver,   case_with_response) }
    it { should_not permit(co_approver,   responded_case) }
    it { should_not permit(co_approver,   closed_case) }


    it { should_not permit(manager,   assigned_trigger_case) }
    it { should_not permit(manager,   new_case) }
    it { should_not permit(manager,   accepted_case) }
    it { should_not permit(manager,   assigned_case) }
    it { should_not permit(manager,   rejected_case) }
    it { should_not permit(manager,   unassigned_case) }
    it { should_not permit(manager,   unassigned_flagged_case) }
    it { should_not permit(manager,   unassigned_trigger_case) }
    it { should_not permit(manager,   case_with_response) }
    it { should_not permit(manager,   responded_case) }
    it { should_not permit(manager,   closed_case) }

    it { should_not permit(responder,   assigned_trigger_case) }
    it { should_not permit(responder,   new_case) }
    it { should_not permit(responder,   accepted_case) }
    it { should_not permit(responder,   assigned_case) }
    it { should_not permit(responder,   rejected_case) }
    it { should_not permit(responder,   unassigned_case) }
    it { should_not permit(responder,   unassigned_flagged_case) }
    it { should_not permit(responder,   unassigned_trigger_case) }
    it { should_not permit(responder,   case_with_response) }
    it { should_not permit(responder,   responded_case) }
    it { should_not permit(responder,   closed_case) }
  end

  permissions :can_view_case_details? do
    it { should     permit(manager,           new_case) }
    it { should     permit(manager,           assigned_case) }
    it { should     permit(manager,           accepted_case) }
    it { should     permit(manager,           rejected_case) }
    it { should     permit(manager,           case_with_response) }
    it { should     permit(manager,           responded_case) }
    it { should     permit(manager,           closed_case) }
    it { should_not permit(responder,         new_case) }
    it { should     permit(responder,         assigned_case) }
    it { should     permit(responder,         accepted_case) }
    it { should_not permit(responder,         rejected_case) }
    it { should     permit(responder,         case_with_response) }
    it { should_not permit(responder,         responded_case) }
    it { should_not permit(responder,         closed_case) }
    it { should_not permit(coworker,          new_case) }
    it { should     permit(coworker,          assigned_case) }
    it { should     permit(coworker,          accepted_case) }
    it { should_not permit(coworker,          rejected_case) }
    it { should     permit(coworker,          case_with_response) }
    it { should_not permit(coworker,          responded_case) }
    it { should_not permit(coworker,          closed_case) }
    it { should_not permit(another_responder, new_case) }
    it { should_not permit(another_responder, assigned_case) }
    it { should_not permit(another_responder, rejected_case) }
    it { should_not permit(another_responder, accepted_case) }
    it { should_not permit(another_responder, case_with_response) }
    it { should_not permit(another_responder, responded_case) }
    it { should_not permit(another_responder, closed_case) }
    it { should     permit(approver,          assigned_flagged_case) }
    it { should     permit(approver,          assigned_trigger_case) }
    it { should     permit(approver,          assigned_case) }
    it { should     permit(approver,          assigned_case) }
  end

  describe 'case scope policy' do
    let(:existing_cases) do
      [
        unassigned_case,
        assigned_case,
        accepted_case,
        rejected_case,
        case_with_response,
        responded_case,
        closed_case,
      ]
    end

    it 'for managers - returns all cases' do
      existing_cases
      manager_scope = described_class::Scope.new(manager, Case.all).resolve
      expect(manager_scope).to match_array(existing_cases)
    end

    it 'for responders - returns only their cases' do
      existing_cases
      responder_scope = described_class::Scope.new(responder, Case.all).resolve
      expect(responder_scope).to match_array([assigned_case, accepted_case, case_with_response, responded_case, closed_case])
    end

    it 'for approvers - returns all cases' do
      existing_cases
      approver_scope = described_class::Scope.new(approver, Case.all).resolve
      expect(approver_scope).to match_array(existing_cases)
    end
  end
end
