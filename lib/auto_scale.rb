class AutoScale

  LOAD_DECREMENT_FACTOR = 2 #2x times

  module LOAD_LISTENER
    SLEEP     = 2 #seconds
    THRESHOLD = 3
  end

  attr_accessor :queue, :stopped, :current_workers_count, :current_pid_switch, :previous_pid_switch, :previous_workers_count

  attr_accessor :interrupted, :high_load

  def monitor
    bind_interrupt_listener
    usage_listener = bind_high_usage_listener
    monitor_workers
  ensure
    Thread.kill(usage_listener) if usage_listener
  end

  def monitor_workers
    loop do
      begin
        if self.interrupted
          exit
          break
        elsif self.high_load
          high_load_decrement
          scale_workers
          self.high_load = false
        else
          increment_or_decrement
        end
      rescue Exception => e
        self.interrupted = true
      end
    end
  end

  def stop(count)
    ScaleWorkers.configuration.stop_procedure(self.queue, count)
  end

  def start(count)
    ScaleWorkers.configuration.start_procedure(self.queue, count)
  end

  def jobs_count
    ScaleWorkers.configuration.count_procedure(self.queue, self.max_failure)
  end

  def exit
    stop self.current_workers_count
  end

  def increment_or_decrement
    if jobs_count > 0
      load = LoadMonitor.can_increase_load?(self.max_cpu_load, self.max_memory_load)    
      self.current_workers_count += self.increment_step if(load  && self.previous_workers_count < self.max_workers)
      self.current_workers_count -= self.decrement_step if(!load && self.previous_workers_count > self.min_workers)
      self.current_workers_count  = 0 if self.current_workers_count < 0
    else
      self.current_workers_count = self.min_workers
    end
    scale_workers
    sleep(self.sleep_time)
  end

  private
  def bind_interrupt_listener
    Signal.trap('TERM') do
      self.interrupted = true
    end

    Signal.trap('INT') do
      self.interrupted = true
    end
  end

  def bind_high_usage_listener
    Thread.new do
      high_load_counter = 0
      loop do
        if LoadMonitor.cpu_load > self.max_cpu_load || LoadMonitor.memory_load > self.max_memory_load
          high_load_counter += 1
        else
          high_load_counter = 0
        end
        self.high_load = true if high_load_counter >= LOAD_LISTENER::THRESHOLD
        sleep(LOAD_LISTENER::SLEEP)
      end
    end
  end

  def scale_workers
    return if self.current_workers_count == self.previous_workers_count
    stop(self.previous_workers_count)
    start(self.current_workers_count)
    self.previous_workers_count = self.current_workers_count
  end

  def high_load_decrement
    self.current_workers_count -= (LOAD_DECREMENT_FACTOR * self.decrement_step)
    self.current_workers_count = 0 if self.current_workers_count < 0
  end

end