class CasePolicy < ApplicationPolicy

  attr_reader :user, :case, :failed_checks

  def initialize(user, kase)
    @case = kase
    super(user, kase)
  end

  def can_view_attachments?
    clear_failed_checks
    # for flagged cases, the state changes to pending_dacu_clearance as soon as a response is
    # added, and comes back to awaiting dacu dispatch if the dd specialist uploads a response
    # and clears, so we want the response always to be visible.
    #
    # for unflagged cases, we don't want the response to be visible when it's in awaiting dispatch
    # because the kilo is still workin gon it.
    #
    if self.case.does_not_require_clearance?
      check_case_is_responded_to_or_closed || check_user_is_a_responder_for_case
    else
      true
    end
  end

  def can_add_attachment_to_flagged_and_unflagged_cases?
    clear_failed_checks
    responder_attachable? || approver_attachable?
  end

  def can_add_attachment?
    clear_failed_checks
    self.case.does_not_require_clearance? && responder_attachable?
  end

  def can_add_attachment_to_flagged_case?
    clear_failed_checks
    self.case.requires_clearance? && responder_attachable?
  end

  def can_upload_response_and_approve?
    clear_failed_checks
    self.case.requires_clearance? && approver_attachable?
  end

  def can_add_case?
    clear_failed_checks
    user.manager?
  end

  def can_assign_case?
    clear_failed_checks
    user.manager? && self.case.unassigned?
  end

  def can_accept_or_reject_approver_assignment?
    clear_failed_checks
    check_user_is_an_approver_for_case &&
      check_no_user_case_approving_assignments_are_accepted
  end

  def can_accept_or_reject_responder_assignment?
    clear_failed_checks
    self.case.awaiting_responder? &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_reassign_approver?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_an_approver_for_case &&
      check_user_is_not_case_approver
  end

  def can_close_case?
    clear_failed_checks
    user.manager? && self.case.responded?
  end

  def can_download_stats?
    user.manager?
  end

  def can_flag_for_clearance?
    clear_failed_checks
    check_user_is_a_manager || check_user_is_an_approver
  end

  def can_take_on_for_approval?
    clear_failed_checks
    check_case_not_already_taken_on_for_approval_by
  end

  def can_unaccept_approval_assignment?
    clear_failed_checks
    check_case_was_accepted_for_approval_by_user
  end

  def can_unflag_for_clearance?
    clear_failed_checks
    check_user_is_an_approver_for_case ||
      (check_user_is_a_manager && check_case_requires_clearance)
  end

  def can_remove_attachment?
    clear_failed_checks
    case self.case.current_state
    when 'awaiting_dispatch'
      user.responding_teams.include?(self.case.responding_team) &&
          self.case.assignments.approving.approved.none?
    else false
    end
  end

  def can_respond?
    clear_failed_checks
    self.case.awaiting_dispatch? &&
      self.case.response_attachments.any? &&
      user.responding_teams.include?(self.case.responding_team)
  end

  def can_approve_case?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_in_current_team &&
      check_case_on_last_step_of_approvals
  end

  def can_escalate_to_next_approval_level?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_in_current_team &&
      !check_case_on_last_step_of_approvals
  end

  def can_approve_or_escalate_case?
    clear_failed_checks
    check_case_requires_clearance &&
      check_user_is_in_current_team
  end

  def can_view_case_details?
    clear_failed_checks
    if user.manager? || user.approver?
      true
    elsif user.responder?
      check_user_is_a_responder_for_case
    end
  end

  def can_add_message_to_case?
    clear_failed_checks
    check_case_is_not_closed && (check_user_is_a_manager || check_user_is_an_approver_for_case || check_user_is_a_responder_for_case)
  end

  def execute_response_approval?
    clear_failed_checks
    check_user_is_an_approver_for_case
  end

  def new_response_upload?
    check_user_is_in_current_team
  end

  def upload_responses?
    check_user_is_in_current_team
  end

  def upload_response_and_return_for_redraft_from_pending_dacu_clearance?
    check_case_is_assigned_to_dacu_disclosure &&
      check_user_is_dacu_disclosure_approver
  end

  def upload_response_and_return_for_redraft_from_pending_press_office_clearance?
    check_case_is_assigned_to_press_office &&
      check_user_is_press_office_approver
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      if user.manager?
        scope.all
      elsif user.responder?
        scope.with_teams(user.responding_teams)
      elsif user.approver?
        scope.all
      else
        Case.none
      end
    end
  end

  private

  # def user_in_responding_team?
  #   @user.in?(self.case.responding_team.users)
  # end

  # def user_not_in_responding_team?
  #   !user_in_responding_team?
  # end


  def approver_attachable?
    self.case.pending_dacu_clearance? && self.case.approvers.first == user
  end

  def responder_attachable?
    check_case_is_in_attachable_state && check_user_is_a_responder_for_case
  end

  check :user_is_a_manager do
    user.manager?
  end

  check :user_is_an_approver do
    user.approver?
  end

  check :user_is_a_responder_for_case do
    user.responding_teams.include?(self.case.responding_team) && !self.case.current_state.in?(['closed', 'responded'])
  end

  check :user_is_an_approver_for_case do
    user.in?(self.case.approving_team_users)
  end

  check :user_is_assigned_approver_for_case do
    user.in?(self.case.approvers)
  end

  check :case_requires_clearance do
    self.case.requires_clearance?
  end

  check :case_has_approvers do
    self.case.approvers.present?
  end

  check :user_is_a_case_approver do
    @user.in? self.case.approvers
  end

  check :user_is_not_case_approver do
    !@user.in? self.case.approvers
  end

  check :user_is_dacu_disclosure_approver do
    @user.in? Team.dacu_disclosure.approvers
  end

  check :user_is_press_office_approver do
    @user.in? Team.press_office.approvers
  end

  # check case_is_in_responder_attachable_state
  check :case_is_in_attachable_state do
    (self.case.drafting? || self.case.awaiting_dispatch?) &&
        self.case.assignments.approving.approved.none?
  end

  check :no_user_case_approving_assignments_are_accepted do
    !self.case.approver_assignments.with_teams(user.approving_team)
      .any?(&:accepted?)
  end

  check :case_is_responded_to_or_closed do
    self.case.responded? || self.case.closed?
  end

  check :case_not_already_taken_on_for_approval_by do
    team = @user.approving_team
    team.present? && !self.case.approver_assignments.map(&:team_id).include?(team.id)
  end

  check :case_was_accepted_for_approval_by_user do
    self.case.approver_assignments.where(user_id: @user.id).any?
  end

  check :case_is_not_closed do
    !self.case.closed?
  end

  check :case_on_last_step_of_approvals do
    begin
      @case.state_machine.next_approval_event == :approve
    rescue Statesman::InvalidStateError
      false
    end
  end

  check :case_is_assigned_to_dacu_disclosure do
    Team.dacu_disclosure.in? @case.approving_teams
  end

  check :case_is_assigned_to_press_office do
    Team.press_office.in? @case.approving_teams
  end

  check :user_is_in_current_team do
    current_info = CurrentTeamAndUserService.new(@case)
    @user.in? current_info.team.users
  end
end
