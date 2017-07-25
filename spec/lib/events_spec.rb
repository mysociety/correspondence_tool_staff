require 'rails_helper'

describe Events do
  let(:machine) do
    Class.new do
      include Statesman::Machine
      include Events
    end
  end
  let(:my_model) { Class.new { attr_accessor :current_state }.new }
  let(:instance) { machine.new(my_model) }

  describe "inclusion" do
    context "after Statesman::Machine" do
      let(:machine) do
        Class.new do
          include Statesman::Machine
          include Statesman::Events
        end
      end

      specify { expect { machine.events }.to_not raise_error }
    end

    context "without Statesman::Machine" do
      let(:machine) { Class.new { include Statesman::Events } }

      it "raises a descriptive error" do
        expect { machine.events }.to raise_error(/without Statesman::Machine/)
      end
    end

    context "before Statesman::Machine" do
      let(:machine) do
        Class.new do
          include Statesman::Events
          include Statesman::Machine
        end
      end

      it "raises a descriptive error" do
        expect { machine.events }.to raise_error(/without Statesman::Machine/)
      end
    end
  end

  describe ".event" do
    before do
      machine.class_eval do
        state :x, initial: true
        state :y
        state :z

        event :event_1 do
          transition from: :x, to: :y
        end

        event :event_2 do
          transition from: :y, to: :z
        end

        event :event_3 do
          guard { false }
          transition from: :x, to: :y
        end
      end
    end

    let(:instance) { machine.new(my_model) }

    context "when the state cannot be transitioned to" do
      it "raises an error" do
        expect { instance.trigger!(:event_2) }.
          to raise_error(Statesman::TransitionFailedError)
      end
    end

    context "when the state can be transitioned to" do
      it "changes state" do
        instance.trigger!(:event_1)
        expect(instance.current_state).to eq("y")
      end

      it "creates a new transition object" do
        expect { instance.trigger!(:event_1) }.
          to change(instance.history, :count).by(1)

        expect(instance.history.first).
          to be_a(Statesman::Adapters::MemoryTransition)
        expect(instance.history.first.to_state).to eq("y")
      end

      it "sends metadata to the transition object" do
        meta = { "my" => "hash" }
        instance.trigger!(:event_1, meta)
        expect(instance.history.first.metadata).to eq(meta)
      end

      it "sets an empty hash as the metadata if not specified" do
        instance.trigger!(:event_1)
        expect(instance.history.first.metadata).to eq({})
      end

      it "returns true" do
        expect(instance.trigger!(:event_1)).to eq(true)
      end

      context "with a guard" do
        let(:result) { true }
        # rubocop:disable UnusedBlockArgument
        let(:guard_cb) { ->(*args) { result } }
        # rubocop:enable UnusedBlockArgument
        before { machine.guard_transition(from: :x, to: :y, &guard_cb) }

        context "and an object to act on" do
          let(:instance) { machine.new(my_model) }

          it "passes the object to the guard" do
            expect(guard_cb).to receive(:call).once.
              with(my_model, instance.last_transition, {}).and_return(true)
            instance.trigger!(:event_1)
          end
        end

        context "which passes" do
          it "changes state" do
            expect { instance.trigger!(:event_1) }.
              to change { instance.current_state }.to("y")
          end
        end

        context "which fails" do
          let(:result) { false }

          it "raises an exception" do
            expect { instance.trigger!(:event_1) }.
              to raise_error(Statesman::GuardFailedError)
          end
        end
      end
    end

    context "when the state has a failing guard" do
      it "raises an error" do
        expect { instance.trigger!(:event_3) }.
          to raise_error(Statesman::GuardFailedError)
      end
    end
  end

  describe '#trigger!' do
    before do
      machine.class_eval do
        state :a, initial: true
        state :b
        state :c

        event :event_1 do
          guard { false }
          transition from: :a, to: :b
        end

        event :event_2 do
          transition from: :a, to: :b, guard: ->(_,_,_) { false }
        end

        event :event_3 do
          transition from: :a, to: :c
        end

        event :event_4 do
          guard { true }
          transition from: :a, to: :b, guard: ->(_,_,_) { true }
        end

        guard_transition(from: :a, to: :c) { |_,_,_| false }
      end
    end

    it 'raises if an event guard fails' do
      expect { instance.trigger! :event_1 }
        .to raise_error(Statesman::GuardFailedError)
    end

    it 'raises if the event transition guard fails' do
      expect { instance.trigger! :event_2 }
        .to raise_error(Statesman::GuardFailedError)
    end

    it 'raises if the transition guard fails' do
      expect { instance.trigger! :event_2 }
        .to raise_error(Statesman::GuardFailedError)
    end

    it 'transitions if no guards fail' do
      instance.trigger! :event_4
      expect(instance.current_state).to eq 'b'
    end
  end

  describe "#available_events" do
    before do
      machine.class_eval do
        state :x, initial: true
        state :y
        state :z

        event :event_1 do
          transition from: :x, to: :y
        end

        event :event_2 do
          transition from: :y, to: :z
        end

        event :event_3 do
          transition from: :x, to: :y
          transition from: :y, to: :x
        end
      end
    end

    let(:instance) { machine.new(my_model) }

    it "should return list of available events for the current state" do
      expect(instance.available_events).to eq([:event_1, :event_3])
      instance.trigger!(:event_1)
      expect(instance.available_events).to eq([:event_2, :event_3])
    end
  end

  describe '#permitted_events' do
    it 'permits events for event guards that succeed' do
      machine.class_eval do
        state :a, initial: true
        state :b
        state :c

        event :event_1 do
          guard { |_,_,_| true }
          transition from: :a, to: :b
        end

        event :event_2 do
          guard { |_,_,_| false }
          transition from: :a, to: :c
        end
      end

      expect(instance.permitted_events(nil)).to eq [:event_1]
    end

    it 'permits events for transition guards that succeed' do
      machine.class_eval do
        state :a, initial: true
        state :b
        state :c
        state :d
        state :e

        event :event_1 do
          guard { |_,_,_| true }
          transition from: :a, to: :b, guard: -> (_,_,_) { true }
          transition from: :a, to: :c, guard: -> (_,_,_) { false }
        end

        event :event_2 do
          guard { |_,_,_| false }
          transition from: :a, to: :d, guard: -> (_,_,_) { true }
        end

        event :event_3 do
          guard { |_,_,_| true }
          transition from: :a, to: :e, guard: -> (_,_,_) { false }
        end
      end

      expect(instance.permitted_events(nil)).to eq [:event_1]
    end

    it 'passes user_id through as metadata' do
      machine.class_eval do
        state :a, initial: true
        state :b
        state :c

        event :event_1 do
          guard { |_,_,metadata| metadata[:user_id] == :id_of_user }
          transition from: :a, to: :b
        end

        event :event_2 do
          transition from: :a, to: :c,
                     guard: ->(_,_,metadata) { metadata[:user_id] == :id_of_user }
        end
      end

      expect(instance.permitted_events(:id_of_user)).to eq [:event_1, :event_2]
    end
  end

  describe '#next_state_for_event' do
    it 'returns the next state a case can transition to for an event' do
      machine.class_eval do
        state :a, initial: true
        state :b
        state :c

        event :event_1 do
          transition from: :a, to: :b
          transition from: :b, to: :c
        end
      end

      instance.trigger(:event_1)
      expect(instance.next_state_for_event(:event_1)).to eq 'c'
    end
  end
end