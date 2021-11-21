module Reform
  class Contract < Disposable::Twin
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

      # Errors compatible with ActiveModel::Errors.
      class Errors
        def initialize(hash)
          @hash = hash
        end

        def [](name)
          dry_messages = @hash[name] or return [] # FIXME: to_sym

          dry_messages.collect { |msg| msg.dry_message.text } #  FIXME: dry::Message specific.
        end

        class Error < Struct.new(:dry_message)

        end
      end

      def errors#(*args)
        # TODO: do that after validate or something?
        name2errors = {}
        @results.collect do |result| # result currently is a {#<Dry::Validation::Result{:title=>"Apocalypse soon"} errors={:album_id=>["is missing"]}>}
          result.errors.each do |m|
            name = m.path[0]

            name2errors[name] ||= []
            name2errors[name] << Errors::Error.new(m)
          end
        end


        Result::Errors.new(name2errors) # DISCUSS: what about nested?
      end

      # def messages(*args); filter_for(:messages, *args) end

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
end
