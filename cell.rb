#!/usr/bin/ruby

require 'set'
require 'board.rb'

class Cell
  attr_reader :max, :x, :y, :number, :candidates

  def determine?() @number != nil end
  def pending?() !determine? end
  def state() @candidates.count.to_s end

  def initialize(max, x, y, number = nil)
    @max = max
    @x = x
    @y = y
    @candidates = number == nil ? Set.new(1..@max) : Set.new([number])
    @groups = Array.new
  end

  def copy(cell)
    @max = cell.max
    @x = cell.x
    @y = cell.y
    @number = cell.number
    @candidates = cell.candidates.dup
  end

  def add_group(group)
    @groups.push(group)
  end

  def delete(number)
    return if determine?
    @candidates.delete(number)
    raise ContradictionError.new() if @candidates.empty?
  end

  def check_determine()
    if @candidates.size == 1
      then determine(@candidates.to_a[0])
    end
  end

  def determine(number)
    @number = number
    @candidates.clear
    @groups.each{ |group| group.determine(@number) }
  end

  def set_reductio(number)
    @candidates = Set.new([number])
  end
end

