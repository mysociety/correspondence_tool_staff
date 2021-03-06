class SearchIndexBuNameUpdaterJob < ApplicationJob

  queue_as :search_index_updater

  def perform(team_id)
    RavenContextProvider.set_context
    bu = BusinessUnit.find(team_id)
    bu.responding_cases.each do | kase |
      kase.update_index
      kase.mark_as_clean!
    end
  end
end
