module Reform
  # Collects all native results of a form of all groups and provides
  # a unified API: #success?, #errors, #messages, #hints.
  # #success? returns validity of the branch.
  class Result #  FIXME: do we really need this, or can we use Dry.rb/AMV result objects directly?
    def initialize(results, nested_results = []) # DISCUSS: do we like this?
      @results = results # native Result objects, e.g. `#<Dry::Validation::Result output={:title=>"Fallout", :composer=>nil} errors={}>`
      @nested_reform_results = nested_results
      @failure = (results + nested_results).find(&:failure?) # TODO: test nested.
    end

    def failure?; @failure  end

    def success?; !failure? end

    require "trailblazer/errors"
    def errors#(*args)
      errors = Trailblazer::Errors.new # TODO: allow injecting.

      # TODO: do that after validate or something?
      @results.collect do |result| # result currently is a {#<Dry::Validation::Result{:title=>"Apocalypse soon"} errors={:album_id=>["is missing"]}>}
        errors.merge_result!(result, path: nil) # TODO: path
      end

      errors
    end

    # def hints(*args);    filter_for(:hints, *args) end

    # def add_error(key, error_text)
    #   CustomError.new(key, error_text, @results)
    # end

    # def to_results
    #   @results
    # end

    # private

    # # this doesn't do nested errors (e.g. )
    # def filter_for(method, *args)






    #   @results.collect { |r| r.public_send(method, *args).to_h }
    #           .inject({}) { |hah, err| hah.merge(err) { |key, old_v, new_v| (new_v.is_a?(Array) ? (old_v |= new_v) : old_v.merge(new_v)) } }
    #           .find_all { |k, v| # filter :nested=>{:something=>["too nested!"]} #DISCUSS: do we want that here?
    #             if v.is_a?(Hash)
    #               nested_errors = v.select { |attr_key, val| attr_key.is_a?(Integer) && val.is_a?(Array) && val.any? }
    #               v = nested_errors.to_a if nested_errors.any?
    #             end
    #             v.is_a?(Array)
    #           }.to_h
    # end
  end
end
