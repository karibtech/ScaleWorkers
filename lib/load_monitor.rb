module LoadMonitor

  def self.vendor
    UsageWatch
  end

  def self.cpu_load
    vendor.uw_cpuused
  end

  def self.memory_load
    vendor.uw_memused
  end

  def self.can_increase_load?(max_cpu_load, max_memory_load)
    increment_count  = 0
    self.load_cycles.times do
      if self.cpu_load < max_cpu_load && self..memory_load < max_memory_load
        increment_count += 1
      else
        increment_count -= 2
      end
      sleep(self.load_sleep_time)
    end
    # increment_count > 0 ? say("Load normal-Increment") : say("Load high-Decrement")
    return increment_count > 0
  end

end