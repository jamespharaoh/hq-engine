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

    def hq_binding
    end

    def compile_xquery source, filename

      @source = source
      @filename = filename

      @proc = Object.instance_eval source, filename

    end

    def run_xquery input, &callback

      context = Context.new
      context.callback = callback
      context.input = input

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
      attr_accessor :input

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

      def get_by_id id

        strings = 
          @callback.call \
            "get record by id",
            { "id" => id }

        nodes =
          strings.map {
            |string|
            XML::Document.string(string).root
          }

        return nodes[0]

      end

      def get_by_id_parts type, id_parts

        strings = 
          @callback.call \
            "get record by id parts",
            {
              "type" => type,
              "id parts" => id_parts,
            }

        nodes =
          strings.map {
            |string|
            XML::Document.string(string).root
          }

        return nodes[0]

      end

      def get *args

        if args.length == 1 && args[0].is_a?(String)

          get_by_id args[0]

        elsif args.length == 1 && args[0].is_a?(Array)

          get_by_id_parts args[0][0], args[0][1..-1]

        elsif args.length > 1

          get_by_id_parts args[0], args[1..-1]

        else

          raise "Error 8891238749"

        end

      end

      def write node
        @results << node
      end

    end

  end

end

end
end

# vim: et ts=2
