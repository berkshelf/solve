module Solve
  module Tracers
    class Silent < AbstractTracer
      class << self
        def empty_method(*args)
          args.each do |method|
            define_method(method.to_sym) do |*args|
            end
          end
        end
      end

      empty_method *AbstractTracer::TRACER_METHODS
    end
  end
end

