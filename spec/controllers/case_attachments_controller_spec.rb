require 'rails_helper'

RSpec.describe CaseAttachmentsController, type: :controller do
  let(:drafter)  { kase.drafter }
  let(:assigner) { create :assigner }

  let(:kase)       { create(:case_with_response) }
  let(:attachment) { kase.attachments.first      }

  describe '#download' do
    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        get :download, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          expect(response).to redirect_to authenticated_root_path
        else
          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    shared_examples 'an authorized user' do
      let(:presigned_url) { "http://pre-signed.com/url" }
      let(:object) { instance_double Aws::S3::Object,
                                     presigned_url: presigned_url }
      before do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attachment.key)
                                           .and_return(object)
      end

      it "redirects to the attachment's url" do
        get :download, params: { case_id: kase.id, id: attachment.id}
        expect(response).to redirect_to presigned_url
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner' do
      before { sign_in assigner }

      it_behaves_like 'an authorized user'
    end

    context 'as a drafter' do
      before { sign_in drafter }

      it_behaves_like 'an authorized user'
    end
  end

  describe '#destroy' do
    let(:attachment_object) do
      instance_double(
        Aws::S3::Object,
        delete: instance_double(Aws::S3::Types::DeleteObjectOutput)
      )
    end

    before do
      allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                         .with(attachment.key)
                                         .and_return(attachment_object)
    end

    shared_examples 'unauthorized user' do
      it 'redirect to the login or root page' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        if subject.current_user
          expect(response).to redirect_to authenticated_root_path
        else
          expect(response).to redirect_to new_user_session_path
        end
        expect(kase.reload.attachments).to include(attachment)
      end
    end

    context 'as an anonymous user' do
      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner with a case that is still open' do
      before { sign_in assigner }

      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner with a case that is still open' do
      before { sign_in assigner }

      it_behaves_like 'unauthorized user'
    end

    context 'as an assigner with a case that has been marked as responded' do
      let(:kase) { create(:responded_case) }

      before { sign_in assigner }

      it_behaves_like 'unauthorized user'
    end

    context 'as a drafter who is still responding to a case' do
      before { sign_in drafter }

      it 'deletes the attachment from the case' do
        delete :destroy, params: { case_id: kase.id, id: attachment.id }
        expect(kase.reload.attachments).not_to include(attachment)
      end
    end

    context 'as a drafter who has marked the case as responded' do
      let(:kase) { create(:responded_case) }

      before { sign_in drafter }

      it_behaves_like 'unauthorized user'
    end
  end
end