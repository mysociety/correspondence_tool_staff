module CaseStates
  extend ActiveSupport::Concern

  def state_machine
    @state_machine ||= ::CaseStateMachine.new(
      self,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end

  def assign_responder(current_user, responding_team)
    managing_team = current_user.managing_team_roles.first.team
    state_machine.assign_responder! current_user,
                                    managing_team,
                                    responding_team
  end

  def responder_assignment_rejected(current_user,
                                    responding_team,
                                    message)
    state_machine.reject_responder_assignment! current_user,
                                               responding_team,
                                               message
  end

  def responder_assignment_accepted(current_user, responding_team)
    state_machine.accept_responder_assignment!(current_user, responding_team)
  end

  # def add_responses(current_user, filenames)
  #   # self.attachments << responses
  #   # filenames = responses.map(&:filename)
  #   state_machine.add_responses!(current_user, responding_team, filenames)
  # end

  # def add_response_to_flagged_case(current_user, filenames)
  #   # self.attachments << responses
  #   # filenames = responses.map(&:filename)
  #   state_machine.add_response_to_flagged_case!(current_user, responding_team, filenames)
  # end

  # def upload_response_and_approve(current_user, approving_team, filenames)
  #   state_machine.upload_response_and_approve!(current_user, approving_team, filenames)
  # end

  def remove_response(current_user, attachment)
    attachment.destroy!
    state_machine.remove_response! current_user,
                                   responding_team,
                                   attachment.filename,
                                   self.reload.attachments.size
  end

  def response_attachments
    attachments.select(&:response?)
  end

  def respond(current_user)
    state_machine.respond!(current_user, responding_team)
  end

  def close(current_user)
    state_machine.close!(current_user, managing_team)
  end
end
