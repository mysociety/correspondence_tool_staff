module PageObjects
  module Pages
    class CasesPage < SitePrism::Page
      set_url '/'

      section :user_card, PageObjects::Sections::UserCardSection, '.user-card'
      sections :case_list, '.case_row' do
        element :number, 'td[aria-label="Case number"]'
        element :name, 'td[aria-label="Requester name"]'
        element :subject, 'td[aria-label="Subject"]'
        element :external_deadline, 'td[aria-label="External deadline"]'
        element :status, 'td[aria-label="Status"]'
        element :who_its_with, 'td[aria-label="Who it\'s with"]'
      end

      section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, '.feedback'

      def case_numbers
        case_list.map do |row|
          row.number.text.delete('Link to case')
        end
      end
    end
  end
end