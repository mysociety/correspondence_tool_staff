class CorrespondenceList < SitePrism::Section
  element :name, '.name'
  element :message, '.message'
  element :category, '.category'
  element :topic, '.topic'
  element :received, '.received'
  element :internal_deadline, '.internal_deadline'
  element :external_deadline, '.external_deadline'
end

class CorrespondenceListPage < SitePrism::Page
  set_url '/'

  sections :correspondence_list, ::CorrespondenceList, '.correspondence_row'
end
