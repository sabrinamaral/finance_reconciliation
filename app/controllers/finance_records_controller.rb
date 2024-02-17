class FinanceRecordsController < ApplicationController
  require 'csv'

  def new
    @differences = []
  end

  def create
    file1 = params[:file1].path
    file2 = params[:file2].path

    csv1 = CSV.read(file1, headers: true, encoding: 'bom|utf-8')
    csv2 = CSV.read(file2, headers: true, encoding: 'bom|utf-8')

    @differences = compare_csvs(csv1, csv2)

    render :new
  end

  private

  def compare_csvs(csv1, csv2)
    differences = []

    csv1.each do |row|
      row2 = csv2.find { |r| r['id'] == row['id'] }

      if row2
        if row.to_h != row2.to_h
          differences << row.to_h.merge(row2.to_h)
          puts "Found difference: #{row.to_h.merge(row2.to_h)}"
        end
      else
        differences << row.to_h
        puts "Found row in csv1 not in csv2: #{row.to_h}"
      end
    end

    csv2.each do |row|
      unless csv1.find { |r| r['id'] == row['id'] }
        differences << row.to_h
        puts "Found row in csv2 not in csv1: #{row.to_h}"
      end
    end

    differences
  end
end
