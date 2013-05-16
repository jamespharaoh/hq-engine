require "hq/logger"
require "hq/tools/base-script"
require "hq/tools/getopt"
require "hq/transform/ruby-backend"
require "hq/transform/transformer"

module HQ
module Transform

class TransformScript < Tools::BaseScript

  attr_accessor :logger
  attr_accessor :transform_backend

  def initialize

    @logger = Logger.new
    @logger.hostname = "local"
    @logger.add_auto "debug"

    @transform_backend = RubyBackend.new

  end

  def main
    process_args
    perform_transform
  end

  def process_args

    @opts, @args =
      Tools::Getopt.process @args, [

        { :name => :input,
          :required => true },

        { :name => :rules,
          :required => true },

        { :name => :include,
          :required => true },

        { :name => :schema,
          :required => true },

        { :name => :output,
          :required => true }

      ]

    @args.empty? \
      or raise "Extra args on command line"

  end

  def perform_transform

    transformer =
      Engine::Transformer.new

    transformer.parent = self

    transformer.schema_file = @opts[:schema]
    transformer.rules_dir = @opts[:rules]
    transformer.include_dir = @opts[:include]
    transformer.input_dir = @opts[:input]
    transformer.output_dir = @opts[:output]

    result =
      transformer.rebuild

    raise "Error" \
      unless result[:success]

  end

end

end
end
