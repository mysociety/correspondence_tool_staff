class Workflows::Predicates
  def initialize(user:, kase:)
    @user = user
    @kase = kase
  end

  def responder_is_member_of_assigned_team?
    if @kase.responding_team
      @kase.responding_team.users.include?(@user)
    else
      false
    end
  end

  def notify_responder_message_received
    NotifyResponderService.new(@kase, 'Message received').call if able_to_send?(@user, @kase)
  end

  def user_is_approver_on_case?
    @user.in?(@kase.approvers)
  end

  def case_can_be_unflagged_for_clearance?
    case_can_be_unflagged_for_clearance_by_disclosure_specialist? ||
      case_can_be_unflagged_for_clearance_by_press_officer? ||
      case_can_be_unflagged_for_clearance_by_private_officer?
  end

  def case_can_be_unflagged_for_clearance_by_disclosure_specialist?
    approver_assignments = @kase.assignments.approving
    disclosure           = BusinessUnit.dacu_disclosure

    @user.approving_team == disclosure &&
      approver_assignments.count == 1 &&
      approver_assignments.first.team == disclosure &&
      (approver_assignments.first.accepted? ||
       approver_assignments.first.pending?)
  end

  def case_can_be_unflagged_for_clearance_by_press_officer?
    approver_assignments = @kase.assignments.approving
    press_office         = BusinessUnit.press_office

    @user.approving_team == press_office &&
      approver_assignments.with_teams(press_office).any?
  end

  def case_can_be_unflagged_for_clearance_by_private_officer?
    approver_assignments = @kase.assignments.approving
    private_office       = BusinessUnit.private_office

    @user.approving_team == private_office &&
      approver_assignments.with_teams(private_office).any?
  end

  def user_is_assigned_disclosure_specialist?
    @kase.assignments.with_teams(BusinessUnit.dacu_disclosure).for_user(@user).present?
  end

  private

  def able_to_send?(user, kase)
    message_not_sent_by_responder?(user, kase) && case_has_responder(kase)
  end

  def message_not_sent_by_responder?(user, kase)
    user != kase.responder_assignment&.user
  end

  def case_has_responder(kase)
    kase.responder_assignment&.user.present?
  end
end
