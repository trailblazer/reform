module Reform::Form::Call
  def call(params, &block)
    bool = validate(params, &block)

    Result.new(bool, self)
  end

  # TODO: the result object might soon come from dry.
  class Result < SimpleDelegator
    def initialize(success, data)
      @success = success
      super(data)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end
  end
end
