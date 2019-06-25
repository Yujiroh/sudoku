#!/usr/bin/ruby

require 'cell.rb'
require 'group.rb'

class Board
  attr_reader :cells, :groups

  #length of square
  def length() @base_width * @base_height end
  #state of calculation
  def state() flatten_cells.map(&:state).join(',') end
  #1 hierarchy of cell
  def flatten_cells() @cells.flatten end

  def initialize(datas, base_width, base_height, reductio_level)
    @datas = datas
    #width of small square
    @base_width = base_width
    #height of small square
    @base_height = base_height
    @reductio_level = reductio_level
    create_cell
    create_group
  end

  def create_cell
    @cells = @datas.map.with_index{ |row, y| row.map.with_index{ |number, x| Cell.new(length, x, y, number) }}
  end

  def create_group
    @groups = Array.new
    #vertical groups
    (0...length).each{ |x| @groups.push(Group.new(@cells.map{ |row| row[x] }, @groups)) }
    #horizontal groups
    @cells.each{ |row| @groups.push(Group.new(row, @groups)) }
    #square groups
    0.step(length - 1, @base_height) do |start_y|
      0.step(length - 1, @base_width) do |start_x|
        @groups.push(Group.new((start_y...start_y + @base_height).map{ |y| (start_x...start_x + @base_width).map{ |x| @cells[y][x] }}.flatten, @groups))
      end
    end
  end

  #解く
  def solve
    loop do
      prev_state = state
      #check if state changed.
      impasse = lambda{ state == prev_state }

      #delete candiates
      delete_method
      only_cell_method
      same_candidate_method
      #hidden_line_method

      #validation
      return BoardStatus::Error if @groups.any? { |group| !group.validated? }
      #check goal?
      return BoardStatus::Goal if flatten_cells.all?(&:determine?)

      #if no effect from normal detection, reductio method is executed.
      if impasse.call then
        (1..@reductio_level).each{ |reductio_level|
          reductio_method(reductio_level)
          break if !impasse.call
        }
      end
      #if no effect from reductio detection, return impasse.
      return BoardStatus::Impasse if impasse.call
    end
  end

  #find one candidate
  def delete_method
    loop do
      prev_state = state
      flatten_cells.each(&:check_determine)
      break if state == prev_state
    end 
  end

  #if candidate number exists in only one cell, 
  def only_cell_method
    @groups.each(&:only_cell_method)
  end

  def same_candidate_method
    @groups.each(&:same_candidate_method)
  end

  def hidden_line_method
    @groups.each(&:hidden_line_method)
  end

  #reductio
  def reductio_method(reductio_level)
    return if reductio_level == 0
 delete_count = 0
    for cell in flatten_cells.select(&:pending?).sort_by{ |cell| cell.candidates.count } do
      next if cell.determine?
      for candidate in cell.candidates do
        board = create_reductio(cell.x, cell.y, candidate, reductio_level - 1)
        begin
          board.solve
        rescue ContradictionError => e
          # if contradiction occured, delete number of reductio from candidates.
          cell.delete(candidate)
delete_count += 1
return if delete_count == 1
#          return
        end
      end
    end
  end

  #create copy for reductio
  def create_reductio(x, y, number, reductio_level)
      board = Board.new(@datas, @base_width, @base_height, reductio_level)
      board.flatten_cells.each_with_index{ |cell, i| cell.copy(flatten_cells[i]) }
      board.groups.each_with_index{ |group, i| group.copy(@groups[i]) }
      board.cells[y][x].set_reductio(number)
      return board
  end

  #print numbers of result
  def print_result
    puts @cells.map{ |row| row.map{ |cell| (cell.determine? ? cell.number : '?').to_s.rjust(length.to_s.length) }.join() }.join("\n")
  end

  #print candidates
  def print_candidates
    flatten_cells.each{ |cell| p cell.x, cell.y, cell.candidates }
  end
end

module BoardStatus
  Goal = 1.freeze
  Impasse = 2.freeze
  Contradiction = 3.freeze
  Error = 4.freeze
end

class ContradictionError < StandardError; end

