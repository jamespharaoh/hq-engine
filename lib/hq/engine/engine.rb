require "xml"
require "yaml"

require "hq/engine/libxmlruby-mixin"
require "hq/transform/transformer"

module HQ
module Engine

class Engine

	include LibXmlRubyMixin

	attr_accessor :logger
	attr_accessor :transform_backend

	attr_accessor :config_dir
	attr_accessor :work_dir

	attr_accessor :results

	def schema_file() "#{work_dir}/schema.xml" end

	def abstract

		return @abstract if @abstract

		abstract = {}

		results.each do
			|result_name, result|

			abstract[result_name] =
				result[:doc].root

		end

		return @abstract = abstract

	end

	def create_work_dir

		if File.exist? "#{work_dir}/error-flag"
			logger.warning "removing work directory due to previous error"
			FileUtils.rm_rf work_dir
		end

		FileUtils.mkdir_p work_dir

	end

	def create_default_schema

		return if File.exists? schema_file

		logger.trace "writing schema.xml (empty)"

		File.open schema_file, "w" do |f|
			f.print "<data>\n"
			f.print "\t<schema name=\"schema\">\n"
			f.print "\t\t<id>\n"
			f.print "\t\t\t<text name=\"name\"/>\n"
			f.print "\t\t</id>\n"
			f.print "\t\t<fields>\n"
			f.print "\t\t</fields>\n"
			f.print "\t\t<table>\n"
			f.print "\t\t\t<col name=\"name\"/>\n"
			f.print "\t\t</table>\n"
			f.print "\t</schema>\n"
			f.print "</data>\n"
		end

	end

	def transform

		return if warn_no_config

		create_work_dir

		create_default_schema

		old_schemas_str =
			File.read schema_file

		loop do

			input_ready

			# process abstract config

			transformer = HQ::Engine::Transformer.new
			transformer.parent = self

			transformer.schema_file = schema_file

			transformer.rules_dir = "#{config_dir}/rules"
			transformer.include_dir = "#{config_dir}/include"

			transformer.input_dir = "#{work_dir}/input"
			transformer.output_dir = "#{work_dir}/output"

			transform_result =
				transformer.rebuild

			# write new schema file

			logger.trace "writing schema.xml"

			new_schemas =
				transformer.data.select {
					|item_id, item_xml|
					item_id =~ /^(schema|schema-option|abstract-rule)\//
				}
				.map {
					|item_id, item_xml|
					item_doc = XML::Document.string item_xml
					item_doc.root
				}

			write_data_file schema_file, new_schemas

			# restart if schema changed

			new_schemas_str =
				File.read schema_file

			if new_schemas_str != old_schemas_str

				old_schemas_str = new_schemas_str
				new_schemas_str = nil

				logger.notice "restart due to schema changes"

				next

			end

			# error if the transform was not complete

			unless transform_result[:success]

				transform_result[:missing_types].each do
					|type_name|
					logger.warning "type missing: #{type_name}"
				end

				transform_result[:remaining_rules].each do
					|rule_name|
					logger.warning "rule could not be run: #{rule_name}"
				end

				logger.die "exiting due to failed transformation"

			end

			# we're done

			load_results

			return

		end

	end

	def warn_no_config
		return false unless $no_config
		return true if @warned_no_config
		logger.warning "not rebuilding configuration due to --no-config option"
		@warned_no_config = true
		return true
	end

	def input_ready
		if $no_database
			logger.warning "using previous input due to --no-database option"
		else
			input_dump
		end
	end

	def input_dump

		logger.notice "loading input from database"

		logger.time "converting input" do

			@input_docs = {}
			@input_strs = {}

			FileUtils.remove_entry_secure "#{work_dir}/input" \
				if File.directory? "#{work_dir}/input"

			FileUtils.mkdir_p "#{work_dir}/input", :mode => 0700

			values_by_type = Hash.new

			inputs = YAML.load File.read "#{work_dir}/input.yaml"

			inputs.each do
				|input|

				id = input["id"]
				type = input["type"]
				value = input["value"]

				value["_id"] = id

				values_by_type[type] ||= Hash.new
				values_by_type[type][id] = value

			end

			schema =
				load_schema_file "#{work_dir}/schema.xml"

			schema_types =
				schema
				.keys
				.map {
					|name|
					name =~ /^schema\/(.+)$/ ? $1 : nil
				}
				.compact
				.sort
				.uniq

			schema_types.each do
				|type|

				values = values_by_type[type] ||= {}

				input_doc = XML::Document.new
				input_doc.root = XML::Node.new "data"

				sorted_values =
					values.values.sort {
						|a,b|
						a["_id"] <=> b["_id"]
					}

				xml_values =
					sorted_values.map {
						|value|
						js_to_xml schema, type, value
					}

				write_data_file \
					"#{work_dir}/input/#{type}.xml",
					xml_values

			end

		end

	end

	def load_results

		@results = {}

		item_path_regex =
			/^#{Regexp.escape work_dir}\/output\/data\/(.+)\.xml$/

		Dir["#{work_dir}/output/data/**/*.xml"].each do
			|item_path|

			item_path =~ item_path_regex
			item_id = $1

			item_doc =
				XML::Document.file \
					item_path,
					:options => XML::Parser::Options::NOBLANKS

			item_dom = item_doc.root
			item_type = item_dom.name

			result = @results[item_type]

			unless result

				result = {}

				result[:doc] = XML::Document.new
				result[:doc].root = XML::Node.new "data"

				@results[item_type] = result

			end

			doc = result[:doc]
			doc.root << doc.import(item_dom)

		end

	end


end

end
end
