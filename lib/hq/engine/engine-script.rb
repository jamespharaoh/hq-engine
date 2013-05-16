require "hq/logger"
require "hq/tools/base-script"
require "hq/tools/getopt"
require "hq/engine/engine"
require "hq/transform/ruby-backend"

module HQ
module Engine

class EngineScript < Tools::BaseScript

  attr_accessor :logger
  attr_accessor :transform_backend

  def initialize

    @logger = Logger.new
    @logger.hostname = "local"
    @logger.add_auto "debug"

    @transform_backend = Transform::RubyBackend.new

  end

  def main
    process_args
    run_engine
  end

  def process_args

    @opts, @args =
      Tools::Getopt.process @args, [

        { :name => :config,
          :required => true },

        { :name => :work,
          :required => true },

      ]

    @args.empty? \
      or raise "Extra args on command line"

  end

  def run_engine

    engine =
      Engine.new

    engine.logger = logger
    engine.transform_backend = transform_backend

    engine.config_dir = @opts[:config]
    engine.work_dir = @opts[:work]

    engine.transform

  end

end

end
end
