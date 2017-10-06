class ResponseUploaderService
  attr_reader :kase, :current_user, :attachment_type, :result

  # action_params is passed through from the flash on the upload page and can be:
  # * 'upload' - upload response but don't change state
  # * 'upload-flagged' - upload response to flagged case and transition to pending_dacu_clearance
  # * 'upload-approve' - approver uploads a response and approves
  # * 'upload-redraft' - approver uploads a response for redrafting to kilo for amendments
  #
  def initialize(kase, current_user, bypass_params_manager, action_params)
    @case = kase
    @current_user = current_user
    @bypass_params_manager = bypass_params_manager
    @uploaded_files = @bypass_params_manager.params[:uploaded_files]
    @result = nil
    @action = action_params
    @type = :response
    @uploader = S3Uploader.new(@case, @current_user)
  end

  def seed!(filepath)
    @uploader.add_file_to_case(filepath, @type)
    PdfMakerJob.perform_now(@case.attachments.first.id)
  end

  def upload!
    if @uploaded_files.blank?
      @result = :blank
    else
      attachments = @uploader.process_files(@uploaded_files, @type)
      transition_state(attachments)
      @result = :ok
      attachments
    end
  rescue Aws::S3::Errors::ServiceError,
         ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotUnique => err
    Rails.logger.error("Error processing uploaded files: #{err.message}")
    @result = :error
  end

  private

  def transition_state(response_attachments)
    ActiveRecord::Base.transaction do
      @case.upload_comment = @bypass_params_manager.params[:upload_comment]
      filenames = response_attachments.map(&:filename)
      case @action
      when 'upload'
        @case.state_machine.add_responses!(@current_user, @case.responding_team, filenames)
      when 'upload-flagged'
        @case.state_machine.add_response_to_flagged_case!(@current_user, @case.responding_team, filenames)
      when 'upload-approve'
        upload_approve(filenames)
      when 'upload-redraft'
        @case.state_machine.upload_response_and_return_for_redraft!(
                             @current_user,
                             @case.approving_teams.with_user(@current_user).first,
                             filenames
        )
      else
        raise "Unexpected action parameter: '#{@action}'"
      end
    end
  end

  def upload_approve(filenames)
    if @bypass_params_manager.present? && @bypass_params_manager.bypass_requested?
      bypass_further_approvals(filenames)
    else
      approve_and_progress_as_normal(filenames)
    end
  end

  def bypass_further_approvals(filenames)
    further_approval_assignments.each { |asgmt| asgmt.bypassed! }
    @case.state_machine.upload_response_approve_and_bypass!(
      @current_user,
      @case.approving_teams.with_user(@current_user).first,
      filenames,
      combined_message
    )
  end

  def further_approval_assignments
    @case.approver_assignments - @case.approver_assignments.for_team(BusinessUnit.dacu_disclosure)
  end

  def combined_message
    msg = "Bypass Reason: #{@bypass_params_manager.message}"
    if @case.upload_comment.present?
      msg += "<br/><br/>File upload comment: #{@case.upload_comment}"
    end
    msg.html_safe
  end

  def approve_and_progress_as_normal(filenames)
    @case.state_machine.upload_response_and_approve!(
      @current_user,
      @case.approving_teams.with_user(@current_user).first,
      filenames
    )
  end

end
