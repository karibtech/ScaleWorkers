module ScaleWorkers
  module Adapter

    class DelayedJobActiveRecord

      include ScaleWorkers::Utils

      PRIME   = 97
      TIMEOUT = 5

      module Command
        START = 'start'
        STOP  = 'stop'
      end

      attr_accessor :pid_switch

      def initialize
        pid_switch = 0
      end

      def stop_procedure
        lambda do |queue, count|
          say('Inside stop procedure')
          adapter = ::ScaleWorkers.configuration.adapter
          pid_dir = adapter.pid_dir(queue)
          adapter.dj_call(adapter.class::Command::STOP, queue, pid_dir, count)
          sleep(adapter.class::TIMEOUT)
        end
      end

      def start_procedure
        lambda do |queue, count|
          say('Inside start procedure')
          adapter = ::ScaleWorkers.configuration.adapter
          adapter.increment_pid_switch
          pid_dir = adapter.pid_dir(queue)
          adapter.dj_call(adapter.class::Command::START, queue, pid_dir, count)
        end
      end

      def count_procedure
        lambda {|queue, max_failure| Delayed::Job.where(queue: queue).where("attempts <= ?", max_failure).count}
      end

      def increment_pid_switch
        ::ScaleWorkers.configuration.adapter.pid = (::ScaleWorkers.configuration.adapter.pid + 1) % PRIME
      end

      def pid_dir(queue)
        File.join(Rails.root.to_s, "tmp", "pids", "#{queue}.#{self.pid}")
      end

      def dj_call(command, queue, pid_dir, count)
        say('DJ call')
        `cd #{Rails.root.to_s}; RAILS_ENV=#{Rails.env} #{::ScaleWorkers.configuration.worker_executable_path} --queue='#{queue}' -p'#{queue}' --pid-dir=#{pid_dir} -n#{count} #{command}`
      end

    end

  end
end