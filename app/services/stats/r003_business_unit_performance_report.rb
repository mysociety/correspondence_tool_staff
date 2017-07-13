module Stats
  class R003BusinessUnitPerformanceReport < BaseReport

    COLUMNS = {
      responded_in_time: 'Responded - in time',
      responded_late: 'Responded - late',
      open_in_time: 'Open - in time',
      open_late: 'Open - late'
    }

    def initialize
      super
      @period_start = Time.now.beginning_of_month
      @period_end = Time.now
      @stats = StatsCollector.new(Team.responding.map(&:name).sort, COLUMNS.values)
      @superheadings = ["#{self.class.title} - #{reporting_period}"]
    end

    def self.title
      'Business Unit Performance Report'
    end

    def self.description
      'Shows all open cases and cases closed this month, in-time or late, by responding team'
    end

    def run
      case_ids = (closed_case_ids + open_case_ids).uniq
      case_ids.each { |case_id| analyse_case(case_id) }
    end

    private

    def closed_case_ids
      Case.closed.where(date_responded: [@period_start..@period_end]).pluck(:id)
    end

    def open_case_ids
      Case.opened.pluck(:id)
    end

    def analyse_case(case_id)
      kase = Case.find case_id
      team = kase.responding_team&.name || 'Unassigned'
      status = kase.closed? ? analyse_closed_case(kase) : analyse_open_case(kase)
      @stats.record_stats(team, COLUMNS[status])
    end

    def analyse_closed_case(kase)
      kase.responded_in_time? ? :responded_in_time : :responded_late
    end

    def analyse_open_case(kase)
      kase.already_late? ? :open_late : :open_in_time
    end
  end
end