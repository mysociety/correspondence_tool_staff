module PageObjects
  module Sections
    module Cases
      class CaseDetailsSection < SitePrism::Section

        section :foi_basic_details, '.foi-basic-details' do

          section :case_type, 'tr.case-type' do
            element :foi_trigger, 'td .foi-trigger'
            element :data, 'td'
          end

          section :date_received, 'tr.date-received' do
            element :data, 'td'
          end

          section :name, 'tr.requester-name' do
            element :data, 'td'
          end

          section :email, 'tr.requester-email' do
            element :data, 'td'
          end

          section :address, 'tr.requester-address' do
            element :data, 'td'
          end

          section :requester_type, 'tr.requester-type' do
            element :data, 'td'
          end

          section :delivery_method, 'tr.delivery-method' do
            element :data, 'td'
          end
        end

        section :sar_basic_details, '.sar-basic-details' do
          section :case_type, 'tr.case-type' do
            element :sar_trigger, 'td .sar-trigger'
            element :data, 'td'
          end

          section :data_subject, 'tr.data-subject' do
            element :data, 'td'
          end

          section :data_subject_type, 'tr.data-subject-type' do
            element :data, 'td'
          end

          section :third_party, 'tr.third-party' do
            element :data, 'td'
          end

          section :date_received, 'tr.date-received' do
            element :data, 'td'
          end

          section :email, 'tr.requester-email' do
            element :data, 'td'
          end

          section :team,  'tr.team' do
            element :data, 'td'
          end
        end



        section :responders_details, '.responder-details' do
          section :team, '.team' do
            element :data, 'td'
          end

          section :name, '.responder-name' do
            element :data, 'td'
          end
        end


        section :response_details, '.response-details' do

          section :date_responded, '.date-responded' do
            element :data, 'td'
          end

          section :timeliness, '.timeliness' do
            element :data, 'td'
          end

          section :time_taken, '.time-taken' do
            element :data, 'td'
          end

          section :info_held, '.info-held' do
            element :data, 'td'
          end
          section :outcome, '.outcome' do
            element :data, 'td'
          end

          section :refusal_reason, '.refusal-reason' do
            element :data, 'td'
          end

          section :exemptions, '.exemptions' do
            elements :list, 'td ul li'
          end
        end

        element :edit_case, :xpath, '//a[contains(.,"Edit case details")]'
      end
    end
  end
end
