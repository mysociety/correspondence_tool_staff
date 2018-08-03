class CaseClosureService

  attr_reader :result, :flash_message

  def initialize(kase, params)
    @kase = kase
    @params = params
    @result = nil
  end

  def call
    #
    #   @case.prepare_for_close
    #   close_params = process_closure_params(@case.type_abbreviation)
    #   if @case.update(close_params)
    #     @case.close(current_user)
    #     set_permitted_events
    #     flash[:notice] = t('notices.case_closed')
    #     redirect_to case_path(@case)
    #   else
    #     set_permitted_events
    #     render :close
    #   end
    # end

    @kase.prepare_for_close
    if @kase.update(@params)
      @flash_message = I18n.t('notices.case_closed')
      @result = :ok
    else
      @result = :error
    end
    self
  end
end
