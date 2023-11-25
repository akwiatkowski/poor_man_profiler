# frozen_string_literal: true

require "benchmark"

# Crystal needs different approach
# possible using macro
# https://github.com/crystal-lang/crystal/issues/403
class Object
  macro methods
    {{ @type.methods.map &.name.stringify }}
  end
end

class PoorManProfiler
  @@pmp_count = Hash(String, Int32).new
  @@pmp_data = Hash(String, Hash(String, Float64)).new

  # you need to run this method before to clear data
  def self.reset_profile_stats
    @@pmp_count = Hash(String, Int32).new
    @@pmp_data = Hash(String, Hash(String, Float64)).new
  end

  # count can be used in calculating time cost of single execution
  def self.append_execution_count(method_key)
    @@pmp_count.pmp_count = Hash(String, Int32).new if @@pmp_data.nil?
    @@pmp_count[method_key] = 0 if @@pmp_count[method_key]?.nil?
    @@pmp_count[method_key] += 1
  end

  def self.append_instance_method_time(klass, method_name, &block)
    method_key = "#{klass}##{method_name}"
    append_time_key(method_key) do
      block.call
    end
  end

  # this is not used yet
  def self.append_class_method_time(klass, method_name, &block)
    method_key = "#{klass}.#{method_name}"
    append_time_key(method_key) do
      block.call
    end
  end

  def self.append_time_key(method_key, &block)
    append_execution_count(method_key)
    @@pmp_data = Hash(String, Hash(String, Float64)).new if @@pmp_data.nil?
    result = nil
    bench = Benchmark.measure { result = block.call }
    if @@pmp_data[method_key].nil?
      @@pmp_data[method_key] = {
        cutime: 0.0,
        real: 0.0,
        stime: 0.0,
        total: 0.0,
        utime: 0.0
      }
    end
    @@pmp_data[method_key].each_key do |key|
      @@pmp_data[method_key][key] += bench.send(key)
    end
    result
  end

  # scan class and wrap all defined (not inherited) instance methods
  # with poor man profiler
  def self.wrap_klass(klass)

    klass.instance_methods(false).each do |method_name|
      puts "+ override method for #{klass}##{method_name}"

      # method params
      klass.send(:methods, method_name).parameters.map { |a| a[1] }

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

  def self.profi_output(key = :real)
    @@pmp_data.keys.sort { |a, b| @@pmp_data[a][key] <=> @@pmp_data[b][key] }.reverse.each do |k|
      puts "#{k}   time: #{@@pmp_data[k][key]}   count: #{@@pmp_count[k]}"
    end
    true
  end
end
