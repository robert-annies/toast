require "ffaker"

module ModelFactory

  def create_records klass, number, &block
    number.times.map do       
      record = klass.new
      yield record
      record.save
      record
    end
  end


  # choose a number of items randomly 
  # from an array of objects and iterate
  def choose range_or_number, array, &block
    
    number = 
      if range_or_number.is_a? Range
        # pick a number in range
        (rand * range_or_number.count).floor + range_or_number.begin
      else        
        range_or_number
      end

    indexes = (0...array.length).to_a.shuffle
    result = []

    indexes[0...number].each do |index|             
      if block_given?
        yield array[index]
      end
      result << array[index]
    end

    result
  end  
end

# creates a rondom date with
require 'date'
module Faker
  class Date
    def self.iso(years_back=5)
      ::Date.ordinal(::Time.now.year - (rand*years_back).floor , (rand*364).ceil).to_s
    end
  end

  class Time
    def self.time
      "#{(rand * 24).floor}:#{(rand * 12).floor * 5}"
    end
  end

  class Number
    def self.integer(range = 1..1000)
      (rand*(range.end - range.begin + 1) + range.begin).floor
    end

    def self.float(range = 0..9)
      (rand*(range.end - range.begin + 1) + range.begin)
    end
  end

  class Boolean
    def self.bool 
      (rand*2) > 1.0 
    end
  end
end

