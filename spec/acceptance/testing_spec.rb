require 'spec_helper'

module Solve
  describe '', :focus do
    def universe
      @universe ||= JSON.parse(File.read(File.expand_path('../../fixtures/universe.json', __FILE__)))
    end

    it 'does something' do
      solver = Solver.new(universe)
      solver.resolve(
        'nginx' => '>= 0.0.0',
        'build-essential' => '~> 1.4'
      )
    end
  end
end
