module ScaleWorkers
  class AutoScale

    include ScaleWorkers::Utils

    LOAD_DECREMENT_FACTOR = 2 #2x times

    module LOAD_LISTENER
      SLEEP     = 2 #seconds
      THRESHOLD = 3
    end

    attr_accessor :queue, :current_workers_count, :previous_workers_count
    attr_accessor :interrupted, :high_load, :config

    def initialize(queue = 'default')
      self.queue = queue
      self.config = ScaleWorkers.configuration
      self.current_workers_count = 0
      self.previous_workers_count = 0
      self.high_load = false
      self.interrupted = false
    end

    def monitor
      # bind_interrupt_listener
      usage_listener = bind_high_usage_listener
      monitor_workers
    ensure
      Thread.kill(usage_listener) if usage_listener
    end

    def monitor_workers
      loop do
        say 'monitoring'
        begin
          if self.interrupted
            exit
            break
          elsif self.high_load
            say('high_load')
            high_load_decrement
            scale_workers
            self.high_load = false
          else
            increment_or_decrement
          end
        rescue Exception => e
          raise e
          self.interrupted = true
        end
      end
    end

    def stop(count)
      config.stop_procedure.call(self.queue, count)
    end

    def start(count)
      config.start_procedure.call(self.queue, count)
    end

    def jobs_count
      config.count_procedure.call(self.queue, config.max_failure)
    end

    def exit
      stop self.current_workers_count
    end

    def increment_or_decrement
      if jobs_count > 0
        load = LoadMonitor.can_increase_load?(config.max_cpu_load, config.max_memory_load)    
        self.current_workers_count += config.increment_step if(load  && self.previous_workers_count < config.max_workers)
        self.current_workers_count -= config.decrement_step if(!load && self.previous_workers_count > config.min_workers)
        self.current_workers_count  = 0 if self.current_workers_count < 0
      else
        self.current_workers_count = config.min_workers
      end
      scale_workers
      sleep(config.sleep_time)
    end

    private
    def bind_interrupt_listener
      Signal.trap('TERM') do
        self.interrupted = true
        say('Term signal received')
      end

      Signal.trap('INT') do
        self.interrupted = true
        say('INT signal received')
      end
    end

    def bind_high_usage_listener
      Thread.new do
        high_load_counter = 0
        loop do
          say 'listening'
          if ScaleWorkers::LoadMonitor.cpu_load > config.max_cpu_load || ScaleWorkers::LoadMonitor.memory_load > config.max_memory_load
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
      self.current_workers_count -= (LOAD_DECREMENT_FACTOR * config.decrement_step)
      self.current_workers_count = 0 if self.current_workers_count < 0
    end

  end
end