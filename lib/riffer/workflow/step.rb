# frozen_string_literal: true
# rbs_inline: enabled

# Define a step for a workflow. It is a simple interface that the user needs to subclass and
# implement the method call. Call should receive and return a hash.
# The user can do the validation if desired.
#
class Riffer::Workflow::Step
  # Executes the step with the given arguments.
  #
  # Raises NotImplementedError if not implemented by subclass.
  #
  #--
  #: (**untyped) -> Hash[Symbol, untyped]
  def call(**kwargs)
    raise NotImplementedError, "#{self.class} must implement #call"
  end
end
