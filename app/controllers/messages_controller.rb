class MessagesController < ApplicationController

  def create
    @case = Case::Base.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)

    begin
      @case.state_machine.add_message_to_case!(
        acting_user: current_user,
        acting_team: case_team,
        message: params[:case][:message_text]
      )
    rescue ActiveRecord::RecordInvalid => err
      if err.record.errors.include?(:message)
        flash[:case_errors] = { message_text: err.record.errors[:message] }
      end
    ensure
      redirect_to case_path(@case, anchor: 'messages-section')
    end
  end

  private

  def case_team
    if current_user.teams_for_case(@case).any?
      current_user.team_for_case(@case)
    else
      User.sort_teams_by_roles(current_user.teams).first
    end
  end

end
