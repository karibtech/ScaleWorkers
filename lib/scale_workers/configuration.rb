module ScaleWorkers
  class Configuration

    attr_accessor :max_failure, :max_workers, :min_workers, :sleep_time, :notification_interval, :increment_step, :decrement_step,
                  :max_memory_load, :max_cpu_load, :load_cycles, :load_sleep_time

    attr_accessor :start_procedure, :stop_procedure, :count_procedure

    attr_accessor :adapter, :worker_executable_path

    def initialize
      self.max_failure           = 5
      self.max_workers           = 5
      self.min_workers           = 1
      self.sleep_time            = 5.minutes
      self.increment_step        = 1
      self.decrement_step        = -2
      self.notification_interval = 15
      # machine load attrs
      self.max_memory_load       = 70
      self.max_cpu_load          = 50
      self.load_cycles           = 5
      self.load_sleep_time       = 10
      self.adapter               = 'delayed_job_active_record'
      self.worker_executable_path = 'script/delayed_job'
    end

    def adapter=(adapter)
      require "scale_workers/adapter/#{adapter}"
      @adapter = "ScaleWorkers::Adapter::#{adapter.classify}".constantize.new
    end

    def start_procedure
      @start_procedure.presence || self.adapter.start_procedure
    end

    def stop_procedure
      @stop_procedure.presence || self.adapter.stop_procedure
    end

    def count_procedure
      @count_procedure.presence || self.adapter.count_procedure
    end

  end
end
