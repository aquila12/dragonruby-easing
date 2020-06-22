# Copyright 2020 Nick Moriarty
#
# This file is provided under the term of the Eclipse Public License, the full
# text of which can be found in EPL-2.0.txt in the licenses directory of this
# repository.

class Graph
  class Scale
    def initialize(x0, x1, y0, y1)
      x_scale = x1 - x0
      y_scale = y1 - y0
      @scale = y_scale / x_scale
      @offset = y0 - x0 * @scale
    end

    def convert(x)
      @scale * x + @offset
    end

    def offset(y)
      @offset -= y
    end
  end

  def initialize(label, n_points, window, axes)
    @label = { x: window[:left], y: window[:top], text: label }
    @window = window
    @n_points = n_points
    @x_axis = Scale.new(axes[:x0], axes[:x1], window[:left], window[:right])
    @y_axis = Scale.new(axes[:y0], axes[:y1], window[:bottom], window[:top])
    @lines = []
  end

  def _draw_axes(target)
    x0 = @x_axis.convert(0)
    y0 = @y_axis.convert(0)
    target.lines << [@window[:left], y0, @window[:right], y0] if y0 > @window[:bottom] && y0 <= @window[:top]
    target.lines << [x0, @window[:bottom], x0, @window[:top]] if x0 > @window[:left] && x0 <= @window[:right]
  end

  def append(x_value, y_value)
    if @lines.count >= @n_points
      x_off = @lines.shift[2] - @window[:left]
      @x_axis.offset(x_off)             # Update the axis window
      @lines.each { |l| l[0] -= x_off; l[2] -= x_off } # Update the lines
    end
    p1 = { x: @x_axis.convert(x_value), y: @y_axis.convert(y_value) }
    ll = @lines.last
    p0 = ll ? { x: ll[2], y: ll[3] } : p1
    @lines << [ p0[:x], p0[:y], p1[:x], p1[:y] ]
    self
  end

  def draw(target)
    _draw_axes(target)
    target.lines << @lines
    target.labels << @label
    self
  end
end
