# Copyright 2020 Nick Moriarty
#
# This file is provided under the term of the MIT License, the full text of
# which can be found in MIT.txt in the licenses directory of this repository.

require 'lib/graph.rb'

module Easing
  def self.identity(x)
    x
  end

  # Raised cubic function with set displacement and velocity
  # f(x)=0 at x=0
  # f(x)=1 at x=1
  # f'(x)=0 at x=0, x=1
  def self.raised_cube(x)
    x * x * (3 - 2 * x)
  end

  # Raised quintic function with set displacement, velocity and acceleration
  # f(x)=0 at x=0
  # f(x)=1 at x=1
  # f'(x)=0 at x=0, x=1
  # f"(x)=0 at x=0, x=1
  def self.raised_quintic(x)
    x2 = x * x
    x * x2 * (10 - 15*x + 6*x2)
  end
end

class Platform
  attr_reader :s, :v, :a

  def initialize(x0, x1, y0, y1, w, h, pause, move, easing = [:identity])
    @pause = pause
    @duration = move
    @function = easing
    @start = (@pause / 2).to_i
    @invert = false
    @r = { x: [x0, x1], y: [y0, y1], w: w, h: h, r:[90, 0], g:[0, 90], b:0 }
  end

  def update_outputs
    @s ||= 0
    @v ||= 0

    s_ = @p
    v_ = (s_ - @s) * 60
    a_ = (v_ - @v) * 60
    @a = a_
    @v = v_
    @s = s_
  end

  def update_state
    p = @start.ease(@duration, @function)
    @p = @invert ? 1-p : p

    if p >= 1
      @start += @pause + @duration
      @invert = !@invert
    end
  end

  def ease()
    update_state
    update_outputs
    Hash[@r.map { |k,v| [k, Array===v ? v[0] + @p * (v[1] - v[0]) : v] }]
  end

  def draw(target)
    target.solids << ease
  end
end

POINTS = 100

PARAMETER_GRAPHS = {
  s: {
    label: 'Displacement',
    axes: { x0: -1, x1: POINTS, y0: -0.1,   y1: 1.1 }
  },
  v: {
    label: 'Velocity',
    axes: { x0: -1, x1: POINTS, y0: -1,  y1: 1 }
  },
  a: {
    label: 'Acceleration',
    axes: { x0: -1, x1: POINTS, y0: -10, y1: 10 }
  },
}

def graph_window(group, parameter)
  y = 500 - 200 * group
  x = { s: 100, v: 500, a: 900 }[parameter]
  {
    left: x, right: x + 300,
    bottom: y, top: y + 100
  }
end

def create_graphs(groups)
  groups.times.map do |n|
    Hash[PARAMETER_GRAPHS.map do |p, config|
      [p, Graph.new(config[:label], POINTS, graph_window(n, p), config[:axes])]
    end]
  end
end

def tick(args)
  dwell_time = 1.seconds
  move_time = 2.seconds

  @platforms ||= [
    Platform.new(200, 880, 600, 600, 200, 50, dwell_time, move_time, [:identity]),
    Platform.new(200, 880, 400, 400, 200, 50, dwell_time, move_time, [:raised_cube]),
    Platform.new(200, 880, 200, 200, 200, 50, dwell_time, move_time, [:raised_quintic])
  ]

  @graphs ||= create_graphs(3)

  @platforms.each { |p| p.draw(args.outputs) }

  t = args.state.tick_count
  @graphs.each_with_index do |g, n|
    p = @platforms[n]
    g[:a].append(t, p.a).draw(args.outputs)
    g[:v].append(t, p.v).draw(args.outputs)
    g[:s].append(t, p.s).draw(args.outputs)
  end
end
