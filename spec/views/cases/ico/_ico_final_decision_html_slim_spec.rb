require 'rails_helper'

describe 'cases/_ico_final_decision.html.slim', type: :view do
  let(:upheld_closed_sar_ico_appeal)      { create(:closed_ico_sar_case).decorate }
  let(:overturned_ico_sar)  { create(:overturned_ico_sar).decorate }

  context 'Closed ICO appeal' do
    before do
      assign(:case, upheld_closed_sar_ico_appeal)
      login_as create(:manager)
      disallow_case_policies upheld_closed_sar_ico_appeal,
                             :can_remove_attachment?
      render partial: 'cases/ico/ico_final_decision.html.slim',
             locals: { case_details: upheld_closed_sar_ico_appeal }
    end

    it 'should display a summary' do
      partial = ico_decision_section(rendered)

      expect(partial).to have_summary
      expect(partial.summary.text).
          to eq "MoJ's decision has been upheld by the ICO on #{upheld_closed_sar_ico_appeal.formatted_date_ico_decision_received}"
    end

    it 'should not display comments if no comments exist' do
      partial = ico_decision_section(rendered)
      expect(partial).to have_no_comments
    end

    it 'should display comments if comments exist' do
      upheld_closed_sar_ico_appeal.ico_decision_comment = 'Today is the day.'

      disallow_case_policies upheld_closed_sar_ico_appeal,
                             :can_remove_attachment?
      render partial: 'cases/ico/ico_final_decision.html.slim',
             locals: { case_details: upheld_closed_sar_ico_appeal }

      partial = ico_decision_section(rendered)
      expect(partial).to have_comments
      expect(partial.comments.text).to eq 'Today is the day.'
    end

    it 'should display attachments' do
      partial = ico_decision_section(rendered)
      expect(partial).to have_attachments
    end
  end

  context 'Overturned SAR' do
    before do
      assign(:case, overturned_ico_sar)
      login_as create(:manager)
      disallow_case_policies overturned_ico_sar,
                             :can_remove_attachment?
      render partial: 'cases/ico/ico_final_decision.html.slim',
             locals: { case_details: overturned_ico_sar }
    end

    it 'should display a summary' do
      partial = ico_decision_section(rendered)

      expect(partial).to have_summary
      expect(partial.summary.text).
          to eq "MoJ's decision has been upheld by the ICO on #{overturned_ico_sar.formatted_date_ico_decision_received}"
    end

    it 'should not display comments if no comments exist' do
      partial = ico_decision_section(rendered)
      expect(partial).to have_no_comments
    end

    it 'should display comments if comments exist' do
      overturned_ico_sar.original_ico_appeal.ico_decision_comment = 'Today is the day.'

      disallow_case_policies overturned_ico_sar,
                             :can_remove_attachment?
      render partial: 'cases/ico/ico_final_decision.html.slim',
             locals: { case_details: overturned_ico_sar }

      partial = ico_decision_section(rendered)
      expect(partial).to have_comments
      expect(partial.comments.text).to eq 'Today is the day.'
    end

    it 'should display attachments' do
      partial = ico_decision_section(rendered)
      expect(partial).to have_attachments
    end

  end
end
