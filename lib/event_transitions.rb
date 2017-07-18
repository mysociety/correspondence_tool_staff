class EventTransitions
  attr_reader :machine, :event_name, :from, :to

  def initialize(machine, event_name, &block)
    @machine    = machine
    @event_name = event_name
    instance_eval(&block)
  end

  def transition(from: nil, to: nil, guard: nil)
    @from = to_s_or_nil(from)
    @to = to_s_or_nil(to)

    machine.transition(from: @from, to: @to)

    machine.events[event_name][:transitions][@from] << { state: @to,
                                                         guard: guard }
  end

  def guard(&block)
    add_callback(callback_type: :guards, &block)
  end

  private

  def add_callback(callback_type: nil, &block)
    validate_callback_type_and_class(callback_type)

    machine.events[event_name][:callbacks][callback_type] << block
  end

  def validate_callback_type_and_class(callback_type)
    if callback_type.nil?
      raise ArgumentError.new("missing keyword: callback_type")
    end
  end

  def to_s_or_nil(input)
    input.nil? ? input : input.to_s
  end

  def array_to_s_or_nil(input)
    Array(input).map { |item| to_s_or_nil(item) }
  end
end