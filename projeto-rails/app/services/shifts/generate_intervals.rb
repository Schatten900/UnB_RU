
module Shifts
  class GenerateIntervals
    def initialize(shift)
      @shift = shift
    end

    def call
      @shift.transaction do
        @shift.shift_intervals.destroy_all

        current_time = @shift.start_time

        while current_time < @shift.end_time
          next_time = [
            current_time + @shift.interval_duration.minutes,
            @shift.end_time
          ].min

          @shift.shift_intervals.create!(
            start_time: current_time,
            end_time: next_time
          )

          current_time = next_time
        end
      end
    end
  end
end



#AI: GPT desktop, no think
#Prompt and strategy: First, we warmed GPT up by asking for file structure given the proposed feature, then we asked for a code with our project's specs, this was consolidated with other .rb