module PermitTriggerEvent
  RSpec::Matchers.define :permit_event_to_be_triggered_only_by do |*permitted_combinations|
    match do |event|
      permitted_combinations.each do |user_and_team, kase|
        unless all_user_teams.key?(user_and_team)
          @error_message = "User #{user_and_team} not found in all_user_teams()."
          return false
        end

        unless all_cases.key?(kase)
          @error_message = "Case #{kase} not found in all_cases()."
          return false
        end
      end


      @errors = []
      all_user_teams.each do |user_type, user_and_team|
        all_cases.each do |case_type, kase|
          user, team = user_and_team
          state_machine = kase.state_machine
          config = state_machine.config_for_event(event_name: event,
                                                  metadata: {
                                                    acting_user: user,
                                                    acting_team: team
                                                  })

          # config.present? would return false for {}, which we don't want.
          if !config.nil? && @transition_to.present?
            next_state = state_machine.next_state_for_event(event,
                                                            acting_user: user,
                                                            acting_team: team)
            # result = !config.nil? && @transition_to == next_state
            result = @transition_to == next_state
          else
            result = !config.nil?
          end

          if [user_type, case_type].in?(permitted_combinations) ^ result
            (binding).pry if @debug_on_error && $stdout.tty?
            # this is handy to be able to step through what failed
            #
            #    kase : the case currently being tested
            #    user : the user currently being tested
            # unexpected_result = state_machine.can_trigger_event?(event_name: event, metadata: {acting_user: user, acting_team: team})
            @errors << [user_type, case_type, !config.nil?]
          end
        end
      end
      @errors.empty?
    end

    chain :with_transition_to do |target_state|
      @transition_to = target_state.to_s
    end

    chain :with_post_hook do |klass, method|
      @post_hook_class = klass
      @post_hook_method = method
    end

    # Use this to run binding.pry if a particular combination fails a test.
    # Handy to be able to get a peek into the context where the error occured.
    # The debugger is also protected so that it doesn't appear if STDOUT is not
    # a TTY.
    chain :debug do
      @debug_on_error = true
    end

    failure_message do |event|
      unless @errors.nil? || @errors.empty?
        @error_message = "Event #{event} failed for the combinations:\n"
        @errors.each do |user_type, kase_type, result|
          if result
            @error_message <<
                "  We did not expect the event to be triggerable for #{user_type} on #{kase_type} cases, but it is.\n"
          else
            @error_message <<
                "  We expected the event to be triggerable for #{user_type} on #{kase_type} cases, but it is not.\n"
          end
        end
      end
      @error_message
    end
  end
end
