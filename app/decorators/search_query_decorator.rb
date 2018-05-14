class SearchQueryDecorator < Draper::Decorator
  delegate_all

  def user_roles
    object.user.roles.join " "
  end

  def user_name
    object.user.full_name
  end

  def query_details
    if object.query_type == 'filter'
      list
    else
      x = object.query.reject{ |name, values| values.blank? }
      x.map { |key, value| "#{key.humanize}: #{value}" }.join(", ")
    end
  end

  def list
    object.query
    x = object.query.reject{ |name, values| values.blank? || name == 'list_path' ||
    name == 'list_params' }
    x.map { |key, value| "#{key.humanize}: #{value.join(', ').humanize}" }.join(", ")
  end
end
