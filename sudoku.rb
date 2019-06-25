#!/usr/bin/ruby

require_relative 'board.rb'

#ナンプレ
class Sudoku
  #hierarchy level of reductio
  ReductioLevel = 2

  #初期化
  def initialize
    @datas = Array.new
    @base_width = 3
    @base_height = 3
  end

  #データ読み込み
  def read_file
    length = lambda{ @base_width * @base_height }
    file = open(ARGV[0])
    lines = File.read(file).split(/\R/)
    @datas = lines.slice(0, @base_width * @base_height).map{ |line| line.strip.split('').map{ |item| item =~ /^[1-9]$/ ? item.to_i : nil }}
    file.close
  end

  #計算
  def solve
    main_board = Board.new(@datas, @base_width, @base_height, ReductioLevel)
    status =  main_board.solve
    case status
    when BoardStatus::Goal then
      puts 'Goal'
    when BoardStatus::Impasse then
      puts 'Impasse'
    when BoardStatus::Error then
      puts 'Error'
    end
    main_board.print_result
  end
end

sudoku = Sudoku.new
sudoku.read_file
sudoku.solve

