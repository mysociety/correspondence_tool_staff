require 'cts/cases/create'
require 'cts/cases/constants'


class Admin::CasesController < AdminController
  before_action :set_correspondence_type,
                only: [
                  :create,
                  :new,
                ]

  def create
    @correspondence_type_key = params.fetch(:correspondence_type).downcase
    case_params = params[case_and_type]

    prepare_flagged_options_for_creation(params)
    case_creator = CTS::Cases::Create.new(Rails.logger, case_params)

    @case = case_creator.new_case
    @selected_state = case_params[:target_state]
    if @case.valid?
      case_creator.call([@selected_state], @case)
      flash[:notice] = "Case created: #{@case.number}"
      redirect_to(admin_cases_path)
    else
      @case.responding_team = BusinessUnit.find(
        case_params[:responding_team]
      )
      prepare_flagged_options_for_displaying
      @target_states = available_target_states
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
      render :new
    end
  end

  def index
    @dates = { }
    5.times do |n|
      date = n.business_days.ago.to_date
      @dates[date] = count_cases_created_on(date)
    end
    @cases = Case::Base.all.order(id: :desc).page(params[:page]).decorate
  end

  def new
    if params[:correspondence_type].present?
      @correspondence_type_key = params[:correspondence_type].downcase
      self.__send__("prepare_new_#{@correspondence_type_key}")
    else
      select_type
    end
  end

  private

  def count_cases_created_on(date)
    Case::Base.where(created_at:  date.beginning_of_day..date.end_of_day).count
  end

  def select_type
    permitted_correspondence_types
    render :select_type
  end

  def prepare_new_foi
    @correspondence_type_key = params[:correspondence_type]
    case_class = correspondence_types_map[@correspondence_type_key.to_sym].first
    @case = case_class.new

    case_creator = CTS::Cases::Create.new(Rails.logger, case_model: Case::Base, type: 'Case::FOI::Standard' )
    @case = case_creator.new_case
    @case.responding_team = BusinessUnit.responding.responding_for_correspondence_type(CorrespondenceType.foi).active.sample
    @case.flag_for_disclosure_specialists = 'no'
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')

    render :new
  end

  def prepare_new_sar
    @correspondence_type_key = params[:correspondence_type]
    case_class = correspondence_types_map[@correspondence_type_key.to_sym].first
    @case = case_class.new

    case_creator = CTS::Cases::Create.new(Rails.logger, case_model: Case::Base, type: 'Case::SAR' )
    @case = case_creator.new_case
    @case.responding_team = BusinessUnit.responding.responding_for_correspondence_type(CorrespondenceType.sar).active.sample
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
    @case.reply_method = 'send_by_email'

    render :new
  end

  def prepare_new_ico
    @correspondence_type_key = params[:correspondence_type]
    case_class = correspondence_types_map[@correspondence_type_key.to_sym].first
    @case = case_class.new

    case_creator = CTS::Cases::Create.new(Rails.logger, case_model: Case::Base, type: 'Case::ICO::FOI' )
    @case = case_creator.new_case
    @case.responding_team = BusinessUnit.responding.responding_for_correspondence_type(CorrespondenceType.ico).active.sample
    @case.flag_for_disclosure_specialists = 'yes'
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')

    render :new
  end

  def permitted_correspondence_types
    @permitted_correspondence_types = [CorrespondenceType.foi, CorrespondenceType.sar, CorrespondenceType.ico]
  end

  def available_target_states
    CTS::Cases::Constants::CASE_JOURNEYS[@correspondence_type_key.to_sym].values.flatten.uniq.sort
  end

  def create_params(correspondence_type)
    case correspondence_type
    when 'foi' then create_foi_params
    when 'sar' then create_sar_params
    when 'ico' then create_ico_params
    end
  end

  def create_foi_params
    params.require(:case_foi).permit(
      :type,
      :requester_type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :target_state,
      :flag_for_disclosure_specialists,
      uploaded_request_files: [],
    )
  end

  def create_sar_params
    params.require(:case_sar).permit(
      :email,
      :flag_for_disclosure_specialists,
      :message,
      :name,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :subject,
      :subject_full_name,
      :subject_type,
      :third_party,
      :reply_method,
      :target_state,
      uploaded_request_files: [],
    ).merge(type: "Case::SAR")
  end

  def create_ico_params
    params.require(:case_ico).permit(
      :ico_officer_name,
      :ico_reference_number,
      :message,
      :original_case_id,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      uploaded_request_files: [],
    ).merge(flag_for_disclosure_specialists: 1)
  end

  def param_flag_for_ds?
    params[case_and_type][:flagged_for_disclosure_specialist_clearance] == '1'
  end

  def param_flag_for_press?
    params[case_and_type][:flagged_for_press_office_clearance] == '1'
  end

  def param_flag_for_private?
    params[case_and_type][:flagged_for_private_office_clearance] == '1'
  end

  def gather_teams_for_flagging
    teams_for_flagging = []
    teams_for_flagging << 'disclosure' if param_flag_for_ds?
    teams_for_flagging << 'press' if param_flag_for_press?
    teams_for_flagging << 'private' if param_flag_for_private?
    teams_for_flagging
  end

  def prepare_flagged_options_for_creation(params)
    if param_flag_for_ds? && !param_flag_for_press? && !param_flag_for_private?
      params[case_and_type][:flag_for_disclosure] = true
    else
      params[case_and_type][:flag_for_team] = gather_teams_for_flagging.join(',')
    end
  end

  def prepare_flagged_options_for_displaying
    @case.approving_teams << BusinessUnit.dacu_disclosure if param_flag_for_ds?
    @case.approving_teams << BusinessUnit.press_office if param_flag_for_press?
    @case.approving_teams << BusinessUnit.private_office if param_flag_for_private?
  end

  def correspondence_types_map
    @correspondence_types_map ||= {
      foi: [Case::FOI::Standard,
            Case::FOI::TimelinessReview,
            Case::FOI::ComplianceReview],
      sar: [Case::SAR],
      ico: [Case::ICO::FOI,
            Case::ICO::SAR]
    }.with_indifferent_access
  end

  def case_and_type
    "case_#{@correspondence_type_key}".to_sym
  end

  def set_correspondence_type
    if params[:correspondence_type].present?
      @correspondence_type = CorrespondenceType.find_by(
        abbreviation: params[:correspondence_type].upcase
      )
    end
  end
end
