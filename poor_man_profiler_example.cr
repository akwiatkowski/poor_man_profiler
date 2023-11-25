require "./poor_man_profiler"

class SlowClass
  def initialize
    sleep 0.05
  end

  def slow_method
    sleep 0.001
  end

  def make_it_so
    10.times do
      slow_method
    end
  end
end

PoorManProfiler.reset_profile_stats
PoorManProfiler.wrap_klass(SlowClass)

SlowClass.new.make_it_so

PoorManProfiler.profi_output

puts 1
