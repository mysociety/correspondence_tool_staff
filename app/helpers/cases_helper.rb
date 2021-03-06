require './lib/translate_for_case'

module CasesHelper

  def download_csv_link(full_path)
    uri = URI(full_path)
    csv_path = "#{uri.path}.csv"
    if uri.query.present?
      csv_path += "?#{uri.query}"
    end
    link_to 'Download cases', csv_path
  end

  def accepted_case_attachment_types
    Settings.case_uploads_accepted_types.join ','
  end

  def case_link_with_hash(kase, field, page, position)
    page = 1 if page.blank?
    if position.nil?
      link_to kase.__send__(field), case_path(kase.id)
    else
      position += 1
      page_offset = Kaminari.config.default_per_page * (page.to_i - 1)
      link_to kase.__send__(field), case_path(kase.id, pos: page_offset + position)
    end

  end

  #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def action_button_for(event)
    case event
    when :assign_responder
      link_to I18n.t('common.case.assign'),
              new_case_assignment_path(@case),
              id: 'action--assign-to-responder',
              class: 'button'
    when :assign_to_new_team
      link_to 'Assign to another team',
              assign_to_new_team_case_assignment_path(@case, @case .responder_assignment),
              id: 'action--assign-new-team',
              class: 'button-secondary'
    when :add_responses
      link_to t('common.case.upload_response'),
              upload_responses_case_path(@case),
              id: 'action--upload-response',
              class: 'button'
    when :create_overturned
      link_to t('common.case.create_overturned'),
              new_overturned_ico_case_path(@case),
              id: 'action--create-overturned',
              class: 'button'
    when :respond
      link_to translate_for_case(@case, "common", 'respond'),
              respond_case_path(@case),
              id: 'action--mark-response-as-sent',
              class: 'button'
    when :reassign_user
      path = nil
      if @assignments.size > 1
        path = select_team_case_assignments_path(@case, assignment_ids: @assignments.map(&:id).join('+'))
      else
        path = reassign_user_case_assignment_path(@case, @assignments.first)
      end
      link_to t('common.case.reassign_case'),
              path,
              id: 'action--reassign-case',
              class: 'button'
    when :approve
      link_to t('common.case.clear_response'),
              approve_case_path(@case),
              id: 'action--approve',
              class: 'button'
    when :request_amends
      link_to t('common.case.request_amends'),
              request_amends_case_path(@case),
              id: 'action--request-amends',
              class: 'button'
    when :upload_response_and_approve
      link_to t('common.case.upload_approve'),
              upload_response_and_approve_case_path(@case),
              id: 'action--upload-approve',
              class: 'button'
    when :upload_response_and_return_for_redraft
      link_to t('common.case.upload_and_redraft'),
              upload_response_and_return_for_redraft_case_path(@case),
              id: 'action--upload-redraft',
              class: 'button'
    when :close, :respond_and_close
      link_to translate_for_case(@case, "common", 'close'),
              close_case_path(@case),
              id: 'action--close-case',
              class: 'button', method: :get
    when :progress_for_clearance
      link_to I18n.t('common.case.progress_for_clearance'),
              progress_for_clearance_case_path(@case),
              id: 'action--progress-for-clearance',
              class: 'button', method: :patch
    when :extend_sar_deadline
      link_to I18n.t('common.case.extend_sar_deadline'),
              extend_sar_deadline_case_path(@case),
              id: 'action--extend-deadline-for-sar',
              class: 'button-secondary'
    when :remove_sar_deadline_extension
      link_to I18n.t('common.case.remove_sar_deadline_extension'),
              remove_sar_deadline_extension_case_path(@case),
              id: 'action--remove-extended-deadline-for-sar',
              class: 'button-secondary', method: :patch
    end
  end
  #rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  def show_hide_message(kase)

    (preview_copy, remaining_copy) = kase.message_extract

    if remaining_copy.nil?
      kase.message
    else
      content_tag(:span, preview_copy, class: 'ellipsis-preview') +
          content_tag(:span,'...', class:'ellipsis-delimiter js-hidden') +
          content_tag(:span, remaining_copy,  class: 'ellipsis-complete js-hidden' ) +
          link_to('Show more', '#', class: 'ellipsis-button js-hidden')
    end
  end

  def attachment_download_link(kase, attachment)
    link_to t('common.case.download_link_html', filename: attachment.filename),
            download_case_case_attachment_path(kase, attachment),
            class: 'download'

  end

  def show_remove_clearance_link(kase)
    if policy(kase).remove_clearance?
      link_to('Remove clearance', remove_clearance_case_path(id: kase.id))
    end
  end

  def attachment_preview_link(attachment)
    if attachment.preview_key != nil
      link_to "View",
                 case_case_attachment_path(attachment.case, attachment),
                 {target: "_blank", class: "view"}
    else
      ''
    end
  end

  def attachment_remove_link(kase, attachment)
    link_to t('common.case.remove_link_html', filename: attachment.filename),
            case_case_attachment_path(kase, attachment),
            {method: :delete, class:"delete",
            remote: true,
            data: {
              confirm: "Are you sure you want to remove #{attachment.filename}?"
            }}
  end

  def exemptions_checkbox_selector(exemption, kase)
    if kase.exemptions.map(&:id).include?(exemption.id)
      'selected'
    else
      ''
    end
  end

  def case_attachments_visible_for_case?
    return false if @case.attachments.response.blank?
    policy(@case).can_view_attachments?
  end

  def case_uploaded_request_files_class
    "error" if @case.errors.include? :uploaded_request_files
  end

  def case_uploaded_request_files_id
    if @case.errors.include? :uploaded_request_files
      "error_case_uploaded_request_files"
    end
  end

  def action_links_for_allowed_events(kase, *events)
    allowed_events = events.find_all do |event_name|
      policy(kase).__send__ "#{event_name}?"
    end
    allowed_events.map do |event_name|
      __send__ "action_link_for_#{event_name}", kase
    end
  end

  def action_link_for_destroy_case(kase)
    link_to 'Delete case', confirm_destroy_case_path(kase)
  end

  def action_link_for_extend_for_pit(kase)
    link_to I18n.t('common.case.extend_for_pit'),
            extend_for_pit_case_path(kase),
            id: 'action--extend-for-pit'

  end

  def action_link_for_remove_pit_extension(kase)
    link_to I18n.t('common.case.remove_pit_extension'),
            remove_pit_extension_case_path(kase),
            id: 'action--remove-pit-extension',
            method: :patch
  end

  def action_link_for_new_case_link(kase)
    link_to "Link a case",
            new_case_link_case_path(kase.id),
            class: 'secondary-action-link',
            id: 'action--link-a-case'
  end

  def action_link_for_destroy_case_link(kase, linked_case)
    if policy(kase).destroy_case_link?
      link_to t('common.case.remove_linked_case_html', case_number: linked_case.number),
              destroy_link_on_case_path(id: kase.id,
                                        linked_case_number: linked_case.number),
              data: { confirm: "Are you sure?" },
              method: :delete
    end
  end

  def request_details_html(kase)
    content_tag(:strong, "#{kase.subject} ", class: 'strong') +
        content_tag(:div, kase.name, class: 'case-name-detail')

  end

  def case_details_links(kase, user)
    links = ''
    if kase.allow_event?(user, :edit_case)
      links << link_to(t('helpers.links.case_details.edit_case'),
                       edit_case_path(kase),
                       class: "secondary-action-link")
    end
    if kase.allow_event?(user, :update_closure)
      links << link_to(t('helpers.links.case_details.edit_closure'),
                       edit_closure_case_path(kase),
                       class: "secondary-action-link")
    end
    links
  end

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias t4c translate_for_case

  def case_details_for_link_type(link_type)
    if link_type.present?
      "#{link_type}-case-details"
    else
      'case-details'
    end
  end

  def manager_updating_close_details_on_old_case?(user, kase)
    # the only reason a manager can't the closure details of a closed case is because
    # it is an "old style" closure, i.e. it was closed before we implemented the new
    # outcomes, info_held statuses, refusal reasons, etc
    user.manager? && kase.closed? && !kase.allow_event?(user, :update_closure)
  end
end
