#!/usr/bin/ruby

require 'set'

class Group
  attr_reader :pending_numbers

  #is line group?
  def line?() [Set.new(@cells.map(&:x)).count, Set.new(@cells.map(&:y)).count].include?(1) end
  #is squre group?
  def rectangle?() !line? end
  #check if exists contradiction?
  def validated?() determine_cells.count == determine_cells.map(&:number).uniq.count end
  #cells which have one candidate
  def determine_cells() @cells.select{ |cell| cell.determine? } end
  #not determined cells
  def pending_cells() @cells.select{ |cell| cell.pending? } end

  def initialize(cells, groups)
    @cells = cells
    @cells.each{ |cell| cell.add_group(self) }
    @pending_numbers = Set.new(1..@cells.count)
    @groups = groups
  end

  def copy(group)
    @pending_numbers = Set.new(group.pending_numbers)
  end

  def determine(number)
    @pending_numbers.delete(number)
    @cells.each{ |cell| cell.delete(number) }
    if pending_cells.count != pending_cells.reduce(Set.new){ |sum, cell| sum += cell.candidates }.size then
      raise ContradictionError.new()
    end
  end

  def only_cell_method
    for number in @pending_numbers do
      cells = pending_cells.select{ |cell| cell.candidates.include?(number) }
      if cells.count == 1 then
        cells[0].determine(number)
      end
    end
  end

  def same_candidate_method
    for cell1 in pending_cells do
      if pending_cells.count{ |cell| cell.candidates == cell1.candidates } == cell1.candidates.count then
        pending_cells.select{ |cell2| cell2.candidates != cell1.candidates }.each{ |cell2| cell2.candidates.subtract(cell1.candidates) }
      end
    end
  end

  def hidden_line_method
    return if line?
    for number in @pending_numbers do
      cells = pending_cells.select{ |cell| cell.candidates.include?(number) }
      if [Set.new(cells.map(&:x)).count, Set.new(cells.map(&:y)).count].include?(cells.count) then
        line_group = @groups.find{ |group| group.line? && group.pending_cells.count{ |cell| cells.include?(cell) } == cells.count }
        if line_group != nil then
          line_group.pending_cells.select{ |cell| !pending_cells.include?(cell) }.each{ |cell| cell.delete(number) }
        end
      end
    end
  end
end

