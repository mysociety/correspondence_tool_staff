require 'csv'

class CSVExporterError < RuntimeError; end

class CSVExporter
  CSV_COLUMN_HEADINGS = [
      'Number',
      'Case type',
      'Current state',
      'Responding team',
      'Responder',
      'Date received',
      'Internal deadline',
      'External deadline',
      'Date responded',
      'Trigger',
      'Name',
      'Requester type',
      'Message',
      'Info held',
      'Outcome',
      'Refusal reason',
      'Exemptions',
      'Postal address',
      'Email',
      'Appeal outcome',
      'Third party',
      'Reply method',
      'SAR Subject type',
      'SAR Subject full name',
      'Business unit responsible for late response'
  ]

  def initialize(kase)
    @kase = kase
  end

  def to_csv #rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    begin
      [
        @kase.number,
        @kase.decorate.pretty_type,
        I18n.t("state.#{@kase.current_state}").downcase,
        @kase.responding_team&.name,
        @kase.responder&.full_name,
        @kase.received_date&.strftime('%F'),
        @kase.flagged? ? @kase.internal_deadline&.strftime('%F') : nil,
        @kase.external_deadline&.strftime('%F'),
        @kase.date_responded.present? ? @kase.date_responded.strftime('%F') : nil,
        @kase.flagged? ? 'Yes' : nil,
        @kase.name,
        @kase.sar? ? nil : @kase.requester_type.humanize,
        dequote_and_truncate(@kase.message),
        @kase.info_held_status&.name,
        @kase.outcome&.name,
        @kase.refusal_reason&.name,
        @kase.exemptions.map{ |x| CaseClosure::Exemption.section_number_from_id(x.abbreviation) }.join(','),
        @kase.postal_address,
        @kase.email,
        @kase.appeal_outcome&.name,
        @kase.respond_to?(:third_party) ? humanize_boolean(@kase.third_party) : nil,
        @kase.respond_to?(:reply_method) ? @kase.reply_method.humanize : nil,
        @kase.respond_to?(:subject_type) ? @kase.subject_type.humanize : nil,
        @kase.respond_to?(:subject_full_name) ? @kase.subject_full_name : nil,
        @kase.decorate.late_team_name
      ]
    rescue => err
      raise CSVExporterError.new("Error encountered formatting case id #{@kase.id} as CSV:\nOriginal error: #{err.class} #{err.message}")
    end
  end

  private
  def dequote_and_truncate(text)
    text.tr('"', '').tr("'", '')[0..4000]
  end

  def humanize_boolean(boolean)
    boolean ? 'Yes' : nil
  end
end
