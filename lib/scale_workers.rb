require 'usagewatch'
require 'active_support'
require 'scale_workers/utils'
require 'active_support/core_ext'
require 'scale_workers/configuration'
require 'scale_workers/auto_scale'
require 'scale_workers/load_monitor'

module ScaleWorkers
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @@configuration ||= Configuration.new
  end

  def self.configure
    yield(self.configuration)
  end
end