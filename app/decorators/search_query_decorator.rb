class SearchQueryDecorator < Draper::Decorator
  delegate_all

  def user_roles
    object.user.roles.join " "
  end

  def user_name
    object.user.full_name
  end

  def query_details
    # TODO delete filters that aren't used
    object.query.to_a.each {|a| a.join " "}.join " "
  end
end
