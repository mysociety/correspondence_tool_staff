require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:responded_trigger_case) { create :case_with_response, :flagged_accepted }
  let(:approver)               { responded_trigger_case.approvers.first }
  let(:service)                { instance_double(CaseApprovalService,
                                                 call: true) }

  describe 'PATCH execute_response_approval' do
    before do
      sign_in approver
      allow(CaseApprovalService).to receive(:new).and_return(service)
    end

    it 'authorizes' do
      expect {
        patch :execute_response_approval, params: { id: responded_trigger_case }
      } .to require_permission(:execute_response_approval?)
              .with_args(approver, responded_trigger_case)
    end

    it 'calls the case approval service' do
      patch :execute_response_approval, params: { id: responded_trigger_case }
      expect(CaseApprovalService).to have_received(:new)
                                       .with(user: approver,
                                             kase: responded_trigger_case)
      expect(service).to have_received(:call)
    end

    it 'flashes a notification' do
      patch :execute_response_approval, params: { id: responded_trigger_case }
      expect(flash[:notice])
        .to eq "You have cleared case #{responded_trigger_case.number}" +
               " - #{responded_trigger_case.subject}."
    end

    it 'redirects to cases page' do
      patch :execute_response_approval, params: { id: responded_trigger_case }
      expect(response).to redirect_to(cases_path)
    end
  end
end