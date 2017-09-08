class Toast::HttpRange
  attr_reader :start, :end, :size

  def initialize range
    if range.nil?
      @start = 0
      @end   = nil
      @size  = nil
    else
      range =~ /\Aitems=(\d*)-(\d*)/
      @start = Integer($1) rescue 0
      @end   = Integer($2) rescue nil
      @end   = nil if (@end and (@end < @start))
      @size  = @end - @start + 1 rescue nil
    end
  end
end
