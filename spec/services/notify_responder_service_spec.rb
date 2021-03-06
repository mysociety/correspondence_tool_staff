require 'rails_helper'

describe NotifyResponderService, type: :service do
  let(:responded_case) { create :responded_case }
  let(:service)        { NotifyResponderService.new(responded_case, 'mail_type') }

  before do
    allow(ActionNotificationsMailer).to receive_message_chain(
                                        :notify_information_officers,
                                        :deliver_later)
  end
  it 'sets the result to ok' do
    service.call
    expect(service.result).to eq :ok
  end

  it 'emails' do
    service.call
    expect(ActionNotificationsMailer).to have_received(:notify_information_officers)
  end
end
