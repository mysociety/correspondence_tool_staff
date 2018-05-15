class SearchQueryDecorator < Draper::Decorator
  delegate_all

  def user_roles
    object.user.roles.join " "
  end

  def user_name
    object.user.full_name
  end

  def search_query_details
    x = object.query.reject{ |name, values| values.blank? || name == 'common_exemption_ids' }
    x.map { |key, value| "#{key.humanize}: #{make_value(key, value)}" }.join(", ")
  end

  def list_query_details
    object.query['list_path']
  end

  def filtered_list_query_details
    x = object.query.reject{ |name, values| values.blank? || name == 'list_path'||
    name == 'list_params' }
    x.map { |key, value| "#{key.humanize}: #{value.join(", " ).humanize }" }.join(", ")
  end

  private

  def make_value(key, value)
    if key == 'filter_assigned_to_ids'
      value.map {|v| "#{Team.find(v).name}" }.join ' '
    else
      value
    end
  end
end
