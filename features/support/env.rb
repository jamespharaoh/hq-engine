require "hq/cucumber/command"
require "hq/cucumber/temp-dir"
require "hq/engine/transformer"
require "hq/logger"
require "hq/tools/getopt"

class Script

  attr_accessor :args
  attr_accessor :status
  attr_accessor :stdout
  attr_accessor :stderr

  def initialize
    @args = []
    @status = 0
    @stdout = $stdout
    @stderr = $stderr
  end

  def main
  end

end

class RubyBackend

  def session
    return Session.new
  end

  def extensions
    [ "rb" ]
  end

  class Session

    def set_library_module name, content
    end

    def compile_xquery source, filename

      @source = source
      @filename = filename

      @proc = Object.instance_eval source, filename

    end

    def run_xquery input, &callback

      context = Context.new
      context.callback = callback

      @proc.call context

      ret = XML::Document.new
      ret.root = XML::Node.new "data"

      context.results.each do
        |node| ret.root << ret.import(node)
      end

      return ret.to_s

    end

    class Context

      attr_accessor :callback
      attr_accessor :results

      def initialize
        @results = []
      end

      def find type
        return @callback.call \
          "search records",
          {
            "type" => type,
          }
      end

      def write node
        @results << node
      end

    end

  end

end

class TransformScript < Script

  include HQ

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

require "pp"
pp result

  end

end

$commands["transform"] = TransformScript
