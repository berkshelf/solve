require 'tsort'
require_relative 'solver/variable_table'
require_relative 'solver/variable_row'
require_relative 'solver/constraint_table'
require_relative 'solver/constraint_row'
require_relative 'solver/serializer'

module Solve
  class Solver
    class << self
      # Create a key to identify a demand on a Solver.
      #
      # @param [Solve::Demand] demand
      #
      # @raise [NoSolutionError]
      #
      # @return [Symbol]
      def demand_key(demand)
        "#{demand.name}-#{demand.constraint}".to_sym
      end

      # Returns all of the versions which satisfy all of the given constraints
      #
      # @param [Array<Solve::Constraint>, Array<String>] constraints
      # @param [Array<Solve::Version>, Array<String>] versions
      #
      # @return [Array<Solve::Version>]
      def satisfy_all(constraints, versions)
        constraints = Array(constraints).collect do |con|
          con.is_a?(Constraint) ? con : Constraint.new(con.to_s)
        end.uniq

        versions = Array(versions).collect do |ver|
          ver.is_a?(Version) ? ver : Version.new(ver.to_s)
        end.uniq

        versions.select do |ver|
          constraints.all? { |constraint| constraint.satisfies?(ver) }
        end
      end

      # Return the best version from the given list of versions for the given list of constraints
      #
      # @param [Array<Solve::Constraint>, Array<String>] constraints
      # @param [Array<Solve::Version>, Array<String>] versions
      #
      # @raise [NoSolutionError] if version matches the given constraints
      #
      # @return [Solve::Version]
      def satisfy_best(constraints, versions)
        solution = satisfy_all(constraints, versions)

        if solution.empty?
          raise Errors::NoSolutionError
        end

        solution.sort.last
      end
    end

    # The world as we know it
    #
    # @return [Solve::Graph]
    attr_reader :graph
    attr_reader :demands
    attr_reader :ui

    attr_reader :domain
    attr_reader :variable_table
    attr_reader :constraint_table
    attr_reader :possible_values

    # @param [Solve::Graph] graph
    # @param [Array<String>, Array<Array<String, String>>] demands
    # @param [#say] ui
    def initialize(graph, demands = Array.new, ui=nil)
      @graph = graph
      @demands = Hash.new
      @ui = ui.respond_to?(:say) ? ui : nil

      @domain = Hash.new
      @possible_values = Hash.new
      @constraint_table = ConstraintTable.new
      @variable_table = VariableTable.new

      Array(demands).each do |l_demand|
        demands(*l_demand)
      end
    end

    # @option options [Boolean] :sorted
    #   return the solution as a sorted list instead of a Hash
    #
    # @return [Hash, List] Returns a hash like { "Artifact Name" => "Version",... }
    #   unless options[:sorted], then it returns a list like [["Artifact Name", "Version],...]
    def resolve(options = {})
      Solve.tracer.start
      seed_demand_dependencies

      while unbound_variable = variable_table.first_unbound
        possible_values_for_unbound = possible_values_for(unbound_variable)
        constraints = constraint_table.constraints_on_artifact(unbound_variable.artifact)
        Solve.tracer.searching_for(unbound_variable, constraints, possible_values)

        while possible_value = possible_values_for_unbound.shift
          possible_artifact = graph.get_artifact(unbound_variable.artifact, possible_value.version)
          possible_dependencies = possible_artifact.dependencies
          all_ok = possible_dependencies.all? { |dependency| can_add_new_constraint?(dependency) }
          if all_ok
            Solve.tracer.trying(possible_artifact)
            add_dependencies(possible_dependencies, possible_artifact)
            unbound_variable.bind(possible_value)
            break
          end
        end

        unless unbound_variable.bound?
          backtrack(unbound_variable)
        end
      end

      solution = (options[:sorted]) ? build_sorted_solution : build_unsorted_solution

      Solve.tracer.solution(solution)

      solution
    end

    def build_unsorted_solution
      {}.tap do |solution|
        variable_table.rows.each do |variable|
          solution[variable.artifact] = variable.value.version.to_s
        end
      end
    end

    def build_sorted_solution
      unsorted_solution = build_unsorted_solution
      nodes = Hash.new
      unsorted_solution.each do |name, version|
        nodes[name] = @graph.get_artifact(name, version).dependencies.map(&:name)
      end

      # Modified from http://ruby-doc.org/stdlib-1.9.3/libdoc/tsort/rdoc/TSort.html
      class << nodes
        include TSort
        alias tsort_each_node each_key
        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end
      begin
        sorted_names = nodes.tsort
      rescue TSort::Cyclic => e
        raise Solve::Errors::UnsortableSolutionError.new(e, unsorted_solution)
      end

      sorted_names.map do |artifact|
        [artifact, unsorted_solution[artifact]]
      end
    end

    # @overload demands(name, constraint)
    #   Return the Solve::Demand from the collection of demands
    #   with the given name and constraint.
    #
    #   @param [#to_s]
    #   @param [Solve::Constraint, #to_s]
    #
    #   @return [Solve::Demand]
    # @overload demands(name)
    #   Return the Solve::Demand from the collection of demands
    #   with the given name.
    #
    #   @param [#to_s]
    #
    #   @return [Solve::Demand]
    # @overload demands
    #   Return the collection of demands
    #
    #   @return [Array<Solve::Demand>]
    def demands(*args)
      if args.empty?
        return demand_collection
      end
      if args.length > 2
        raise ArgumentError, "Unexpected number of arguments. You gave: #{args.length}. Expected: 2 or less."
      end

      name, constraint = args
      constraint ||= ">= 0.0.0"

      if name.nil?
        raise ArgumentError, "A name must be specified. You gave: #{args}."
      end

      demand = Demand.new(self, name, constraint)
      add_demand(demand)
    end

    # Add a Solve::Demand to the collection of demands and
    # return the added Solve::Demand. No change will be made
    # if the demand is already a member of the collection.
    #
    # @param [Solve::Demand] demand
    #
    # @return [Solve::Demand]
    def add_demand(demand)
      unless has_demand?(demand)
        @demands[self.class.demand_key(demand)] = demand
      end

      demand
    end
    alias_method :demand, :add_demand

    # @param [Solve::Demand, nil] demand
    def remove_demand(demand)
      if has_demand?(demand)
        @demands.delete(self.class.demand_key(demand))
      end
    end

    # @param [Solve::Demand] demand
    #
    # @return [Boolean]
    def has_demand?(demand)
      @demands.has_key?(self.class.demand_key(demand))
    end

    private

      # @return [Array<Solve::Demand>]
      def demand_collection
        @demands.collect { |name, demand| demand }
      end

      def seed_demand_dependencies
        add_dependencies(demands, :root)
      end

      def can_add_new_constraint?(dependency)
        current_binding = variable_table.find_artifact(dependency.name)
        #haven't seen it before, haven't bound it yet or the binding is ok
        current_binding.nil? || current_binding.value.nil? || dependency.constraint.satisfies?(current_binding.value.version)
      end

      def possible_values_for(variable)
        possible_values_for_variable = possible_values[variable.artifact]
        if possible_values_for_variable.nil?
          constraints_for_variable = constraint_table.constraints_on_artifact(variable.artifact)
          all_values_for_variable = domain[variable.artifact]
          possible_values_for_variable = constraints_for_variable.inject(all_values_for_variable) do |remaining_values, constraint|
            remaining_values.reject { |value| !constraint.satisfies?(value.version) }
          end
          possible_values[variable.artifact] = possible_values_for_variable
        end
        possible_values_for_variable
      end

      def add_dependencies(dependencies, source)
        dependencies.each do |dependency|
          next if (source.respond_to?(:name) && dependency.name == source.name)
          Solve.tracer.add_constraint(dependency, source)
          variable_table.add(dependency.name, source)
          constraint_table.add(dependency, source)
          dependency_domain = graph.versions(dependency.name, dependency.constraint)
          domain[dependency.name] = [(domain[dependency.name] || []), dependency_domain]
          .flatten
          .uniq
          .sort { |left, right| right.version <=> left.version }

          #if the variable we are constraining is still unbound, we want to filter
          #its possible values, if its already bound, we know its ok to add this constraint because
          #we can never change a previously bound value without removing this constraint and we check above
          #whether or not its ok to add this constraint given the current value

          variable = variable_table.find_artifact(dependency.name)
          if variable.value.nil?
            reset_possible_values_for(variable)
          end

        end
      end

      def reset_possible_values_for(variable)
        Solve.tracer.reset_domain(variable)
        possible_values[variable.artifact] = nil
        possible_values_for(variable).tap { |values| Solve.tracer.possible_values(values) }
      end

      def backtrack(unbound_variable)
        Solve.tracer.backtrack(unbound_variable)
        previous_variable = variable_table.before(unbound_variable.artifact)

        if previous_variable.nil?
          Solve.tracer.cannot_backtrack
          raise Errors::NoSolutionError
        end

        Solve.tracer.unbind(previous_variable)

        source = previous_variable.value
        removed_variables = variable_table.remove_all_with_only_this_source!(source)
        removed_variables.each do |removed_variable|
          possible_values[removed_variable.artifact] = nil
          Solve.tracer.remove_variable(removed_variable)
        end
        removed_constraints = constraint_table.remove_constraints_from_source!(source)
        removed_constraints.each do |removed_constraint|
          Solve.tracer.remove_constraint(removed_constraint)
        end
        previous_variable.unbind
        variable_table.all_after(previous_variable.artifact).each do |variable|
          new_possibles = reset_possible_values_for(variable)
        end
      end
  end
end
