module PageObjects
  module Pages
    module Cases
      class RespondPage < SitePrism::Page
        set_url '/cases/{id}/respond'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :reminders,    '.reminders'
        element :alert,        '.notice'
        element :mark_as_sent_button, 'a.button'
        element :back_link,  'a.button-secondary'


      end
    end
  end
end
