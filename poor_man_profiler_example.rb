require "./poor_man_profiler"

class SlowClass
  def initialize
    sleep 0.05
  end

  def slow_method(param = 1)
    sleep 0.001
  end

  def make_it_so
    (0...10).each do |i|
      slow_method(i)
    end
  end
end

reset_profile_stats
wrap_klass(SlowClass)

SlowClass.new.make_it_so

profi_output
