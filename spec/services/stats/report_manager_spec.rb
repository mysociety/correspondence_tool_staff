require 'rails_helper'

module Stats
  describe ReportManager do

    let(:manager)  { ReportManager.new}

    describe '#reports' do
      it 'returns a hash of reports indexed by report_id' do
        expect(manager.reports).to eq ReportManager::REPORTS
      end
    end

    describe '#report_class' do
      it 'returns the class of the report with the given index' do
        expect(manager.report_class('R002')).to eq R002OpenFoiCasesByTeamReport
      end
    end

    describe '#report_object' do
      it 'returns an instantiated oject' do
        expect(manager.report_object('R001')).to be_instance_of(R001RespondedCaseTimelinessReport)
      end
    end

    describe '#filename' do
      it 'returns the filename for the given report' do
        expect(manager.filename('R002')).to eq 'r002_open_foi_cases_by_team_report.csv'
      end
    end
  end
end
