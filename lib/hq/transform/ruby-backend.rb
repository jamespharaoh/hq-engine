module HQ
module Transform

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

        strings =
          @callback.call \
            "search records",
            {
              "type" => type,
            }

        nodes =
          strings.map {
            |string|
            XML::Document.string(string).root
          }

        return nodes

      end

      def write node
        @results << node
      end

    end

  end

end

end
end
