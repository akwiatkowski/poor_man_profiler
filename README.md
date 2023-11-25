# Poor man's profiler

Please check poor_man_profiler_example.rb

```
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

reset_profile_stats
wrap_klass(SlowClass)

SlowClass.new.make_it_so

profi_output
```

and it's output

```
+ override method for SlowClass#slow_method
+ override method for SlowClass#make_it_so
SlowClass#make_it_so   time: 0.011738444009097293   count: 1
SlowClass#slow_method   time: 0.011554540949873626   count: 10
```
