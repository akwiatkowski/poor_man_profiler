# frozen_string_literal: true

require "benchmark"

# you need to run this method before to clear data
def reset_profile_stats
  $pmp_count = {}
  $pmp_data = {}
end

# count can be used in calculating time cost of single execution
def append_execution_count(method_key)
  $pmp_count = {} if $pmp_data.nil?
  $pmp_count[method_key] = 0 if $pmp_count[method_key].nil?
  $pmp_count[method_key] += 1
end

def append_instance_method_time(klass, method_name, &block)
  method_key = "#{klass}##{method_name}"
  append_time_key(method_key) do
    block.call
  end
end

# this is not used yet
def append_class_method_time(klass, method_name, &block)
  method_key = "#{klass}.#{method_name}"
  append_time_key(method_key) do
    block.call
  end
end

def append_time_key(method_key, &block)
  append_execution_count(method_key)
  $pmp_data = {} if $pmp_data.nil?
  result = nil
  bench = Benchmark.measure { result = block.call }
  if $pmp_data[method_key].nil?
    $pmp_data[method_key] = {
      cutime: 0.0,
      real: 0.0,
      stime: 0.0,
      total: 0.0,
      utime: 0.0
    }
  end
  $pmp_data[method_key].each_key do |key|
    $pmp_data[method_key][key] += bench.send(key)
  end
  result
end

# scan class and wrap all defined (not inherited) instance methods
# with poor man profiler
def wrap_klass(klass)
  klass.instance_methods(false).each do |method_name|
    puts "+ override method for #{klass}##{method_name}"

    # method params
    params = klass.send(:instance_method, method_name).parameters.map { |a| a[1] }

    # rename method
    wrapped_method = "_wrapped_#{method_name}".to_sym
    klass.send(:alias_method, wrapped_method, method_name)
    klass.send(:remove_method, method_name)

    # wrap method
    klass.send(:define_method, method_name) do |*params|
      append_instance_method_time(klass.to_s, method_name) do
        send(wrapped_method, *params)
      end
    end
  end
end

def profi_output(key = :real)
  $pmp_data.keys.sort { |a, b| $pmp_data[a][key] <=> $pmp_data[b][key] }.reverse.each do |k|
    puts "#{k}   time: #{$pmp_data[k][key]}   count: #{$pmp_count[k]}"
  end
  true
end
