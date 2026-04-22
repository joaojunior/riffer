# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Workflow is the base class for all workflows in the Riffer framework.
#
# Subclass this to create your own workflows.
# Provides a simple DSL for defining steps.
# See Riffer::Agent, Riffer::Tool.
#
# In case of success, a Riffer::Workflow::Response is returned in the method run.
# The exceptions Riffer::ValidationError, Riffer::ArgumentError, Riffer::Error, and Riffer::TimeoutError
# are captured, and a response with the error is returned. All other exceptions are not being suppressed.
#
# In the example below, MyWorkflow defines 4 steps: search1, search2, search3, search4. search1 does not
# depends in any steps, search2 depends_on search1, search3 does not have any dependency, and
# search4 depends on search1 and search2. All results from previous steps are available for the current
# step to consume.
# If a step has no dependencies, it will receive the initial parameters passed to the method run.
#
#   class MyAgent < Riffer::Agent
#     model 'openai/gpt-4o'
#     instructions 'You are a helpful assistant.'
#   end
#
#   class MyStep < Riffer::Workflow::Step
#     def call(**kwargs)
#       context = kwargs.delete(:context)
#       prompt = kwargs.values.join(" ")
#       agent = MyAgent.new
#       agent.generate(prompt, context: context)
#     end
#   end
#
#   class MyWorkflow < Riffer::Workflow
#     step :search1, MyStep
#     step :search2, MyStep, depends_on: :search1
#     step :search3, MyStep
#     step :search4, MyStep, depends_on: [:search1, :search2]
#   end
#
#   workflow = MyWorkflow.new
#   workflow.run(context:nil, prompt: "Hello!")
#
class Riffer::Workflow
  extend Riffer::Toolable

  kind :workflow
  VALID_STEP_RESPONSE = [Riffer::Agent::Response, Riffer::Tools::Response, Riffer::Workflow::Response].freeze
  DEFAULT_TIMEOUT = 60 #: Integer

  # We use a class instance variable to store steps for each specific subclass
  #
  #: () -> Array[Hash[Symbol, untyped]]
  def self.steps
    @steps ||= []
  end

  # 'DSL' method to define a step
  # we will update it later to also accept Riffer::Workflow
  #
  #--
  #: (Symbol, singleton(Riffer::Workflow::Agent), ?Hash[Symbol, untyped]) -> Array[Hash[Symbol, untyped]]
  def self.step(name, step_class, options = {})
    steps << {
      name: name,
      step_class: step_class,
      depends_on: Array(options[:depends_on]) # Ensure it's always an array
    }
  end

  # Initializes a new workflow.
  #
  #--
  #: () -> void
  def initialize
    @results = {}
    @default_input = {}
    @context = {}
  end

  # Run all the workflow steps
  #
  #--
  #: (context: Hash[Symbol, untyped], **untyped) -> Riffer::Workflow::Response
  def run(context:, **kwargs)
    @context = context
    @default_input = kwargs

    self.class.steps.each do |step_config|
      @results[step_config[:name]] = run_step(step_config: step_config)
    end

    Riffer::Workflow::Response.success(identifier: self.class.identifier, steps_response: @results)
  rescue Riffer::TimeoutError => e
    Riffer::Workflow::Response.error(
      identifier: self.class.identifier, steps_response: @results, message: e.message, type: :execution_error
    )
  rescue Riffer::ValidationError, Riffer::ArgumentError, Riffer::Error => e
    Riffer::Workflow::Response.error(
      identifier: self.class.identifier, steps_response: @results, message: e.message, type: :validation_error
    )
  end

  private

  # Execute step with timeout handling.
  #
  # Raises Riffer::TimeoutError if execution exceeds the configured timeout.
  # Raises Riffer::ValidationError if payload are not correct.
  #
  #--
  #: (step_config: Hash[Symbol, untyped]) -> Hash[Symbol, untyped]
  def run_step(step_config:)
    sliced = @results.slice(*step_config[:depends_on])
    payload = sliced.empty? ? @default_input : sliced

    Timeout.timeout(self.class.timeout) do
      step = step_config[:step_class].new
      step.call(**payload)
    end
  rescue Timeout::Error
    raise Riffer::TimeoutError, "Step execution timed out after #{self.class.timeout} seconds"
  rescue ArgumentError => e
    raise Riffer::ValidationError, "Step execution with incorrect input: #{payload}. #{e.message}"
  end
end
