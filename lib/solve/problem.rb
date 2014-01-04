module Solve
  class Problem
    attr_reader :name
    attr_reader :must
    attr_reader :available
    attr_reader :failed
    attr_reader :dependents
    attr_reader :elect

    def initialize(solver, name, demand, candidates)
      @solver = solver
      @name = name
      @demand = demand
      @available = []
      @failed = {}
      @elect = nil
      @dependents = {}

      add_candidates(candidates)

      raise Errors::NoSolutionError unless @available.any?
    end

    def solved?
      !!@elect
    end

    def solve!
      return @elect if solved?

      candidates do |candidate|
        puts "#{@name} tries #{candidate}"
        if test(candidate)
          @elect = candidate
          puts "#{@name} uses #{candidate}"
          return candidate
        end
      end

      if @dependents.any?
        # TODO: improve detection here
        remove_dependent(@dependents.keys.last)
        return nil
      end

      raise Errors::NoSolutionError, "could not find a suitable candidate for #{@name} (#{(@dependents.values + [@demand]).compact.join(', ')}) from #{available.map(&:version)}"
    end

    def depending(dependent, constraint)
      return if @elect && !constraint.satisfies?(@elect.version)

      # TODO: don't add dependent if conflict (no candidates available, conflict with existing dependent constraints)
      add_dependent(dependent, constraint)
    end

    def fail!(reason)
      puts "#{@name} brings down #{@elect}"
      remove_candidate(@elect, reason)
      @elect = nil
    end

    private

      def test(candidate)
        candidate.dependencies.each do |dependency|
          problem = @solver.problem_for(dependency.name)
          unless problem.depending(self, dependency.constraint)
            return false
          end
        end

        true
      end

      # Make sure all available artifacts satisfy the given demand
      def add_candidates(candidates)
        candidates.each do |candidate|
          if !@demand || @demand.satisfies?(candidate.version)
            @available << candidate
          else
            remove_candidate(candidate, @demand)
          end
        end

        # TODO: insert sorted instead
        @available = @available.sort.reverse
      end

      def remove_candidate(candidate, reason)
        @failed[reason] ||= []
        @failed[reason] << candidate
        @available.delete(candidate)
      end

      def candidates(&block)
        if @dependents.any?
          constraints = @dependents.values
          @available.select do |candidate|
            if constraints.all? { |constraint| constraint.satisfies?(candidate.version) }
              block.call(candidate)
            end
          end
        else
          @available.each(&block)
        end
      end

      def add_dependent(dependent, constraint)
        puts "#{dependent.name} depends on #{@name} with #{constraint}"
        @dependents[dependent] = constraint
      end

      def remove_dependent(dependent)
        constraint = @dependents.delete(dependent)
        # TODO: reset failed candidates for this constraint
        puts "#{@name} removes dependent #{dependent.name} with #{constraint}"
        dependent.fail!(constraint)
      end

  end
end
