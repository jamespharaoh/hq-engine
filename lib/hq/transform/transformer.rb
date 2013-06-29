require "hq/engine/libxmlruby-mixin"
require "hq/engine/rule-error"

module HQ
module Engine
class Transformer

	include LibXmlRubyMixin

	attr_accessor :parent

	def logger() parent.logger end
	def transform_backend() parent.transform_backend end

	attr_accessor :schema_file
	attr_accessor :rules_dir
	attr_accessor :include_dir
	attr_accessor :input_dir
	attr_accessor :output_dir

	attr_reader :data

	def load_schema

		@schemas =
			load_schema_file schema_file

	end

	def load_rules

		logger.debug "loading transformation rules"

		@rules = {}

		Dir.glob("#{rules_dir}/**/*").each do
			|filename|

			extensions_re =
				"(?:%s)" % [
					transform_backend.extensions
						.map { |ext| Regexp.quote ext }
						.join("|")
				]

			next unless filename =~ /^
				#{Regexp.quote "#{rules_dir}/"}
				(
					(.+)
					\. (#{extensions_re})
				)
			$/x

			rule = {}
			rule[:name] = $2
			rule[:type] = $3
			rule[:filename] = "#{$2}.#{$3}"
			rule[:path] = filename
			rule[:source] = File.read rule[:path]

			@rules[rule[:name]] = rule

		end

		@rules = Hash[@rules.sort]

	end

	def read_transforms

		got_error = false

		@transforms = {}

		@schemas.each do
			|key, transform_elem|

			next unless key =~ /^transform\//

			transform = {
				name: transform_elem["name"],
				rule: transform_elem["rule"],
			}

			transform[:in] =
				transform_elem.find("input").map {
					|input_elem|
					input_elem["name"]
				}

			transform[:out] =
				transform_elem.find("output").map {
					|input_elem|
					input_elem["name"]
				}

			transform[:matches] =
				transform_elem.find("match").map do
					|match_elem|

					match = {
						type: match_elem["type"],
						fields: match_elem.find("field").map do
							|field_elem|

							field = {
								name: field_elem["name"],
								as: field_elem["as"],
							}

							field

						end,
					}

					unless transform[:in].include? match[:type]

						logger.error "transform '%s' matches type '%s' which " \
							"is not listed as an input" % [
								transform[:name],
								match[:type],
							]

						got_error = true

					end

					match

				end

			@transforms[transform_elem["name"]] =
				transform

			# sanity check

			unless @rules[transform[:rule]]

				logger.error "no such rule %s for transform %s" % [
					transform[:rule],
					transform[:name],
				]

				got_error = true

			end

		end

		return ! got_error

	end

	def init_backend_session

		@backend_session =
			transform_backend.session

		# add hq module
		# TODO move this somewhere

		@backend_session.set_library_module \
			"hq",
			"
				module namespace hq = \"hq\";

				declare function hq:get (
					$id as xs:string
				) as element () ?
				external;

				declare function hq:get (
					$type as xs:string,
					$id-parts as xs:string *
				) as element () ?
				external;

				declare function hq:find (
					$type as xs:string
				) as element () *
				external;
			"

	end

	def transform

		logger.notice "performing transformation"

		logger.time "performing transformation" do

			remove_output

			init_backend_session

			@data = {}

			load_schema
			load_rules
			load_input
			load_includes

			read_transforms or return false

			@remaining_transforms =
				@transforms.clone

			pass_number = 0

			loop do

				num_processed =
					transform_pass pass_number

				break if num_processed == 0

				pass_number += 1

			end

		end

		return {
			:success => @remaining_transforms.empty?,
			:remaining_transforms => @remaining_transforms.keys,
			:missing_types =>
				(
					@remaining_transforms
						.values
						.map { |transform| transform[:in] }
						.flatten
						.uniq
						.sort
				) - (
					@schema_types
						.to_a
						.select { |type| type =~ /^schema\// }
						.map { |type| type.gsub /^schema\//, "" }
				)
		}

	end

	def load_input

		logger.debug "reading input from disk"

		logger.time "reading input from disk" do

			Dir["#{input_dir}/*.xml"].each do
				|filename|

				input_data =
					load_data_file filename

				input_data.each do
					|item_dom|

					store_data item_dom

				end

			end

		end

	end

	def load_includes

		Dir["#{include_dir}/*.xquery"].each do
			|path|

			path =~ /^ #{Regexp.quote include_dir} \/ (.+) $/x
			name = $1

			@backend_session.set_library_module \
				name,
				File.read(path)

		end

	end

	def remove_output

		if File.directory? output_dir
			FileUtils.remove_entry_secure output_dir
		end

		FileUtils.mkdir output_dir

	end

	def transform_pass pass_number

		logger.debug "beginning pass #{pass_number}"

		@incomplete_types =
			Set.new(
				@remaining_transforms.map {
					|transform_name, transform|
					transform[:out]
				}.flatten.uniq.sort
			)

		@schema_types =
			Set.new(
				@schemas.keys
			)

		transforms_for_pass =
			Hash[
				@remaining_transforms.select do
					|transform_name, transform|

					missing_input_types =
						transform[:in].select {
							|in_type|
							@incomplete_types.include? in_type
						}

					missing_input_schemas =
						transform[:in].select {
							|in_type|
							! @schema_types.include? "schema/#{in_type}"
						}

					missing_output_schemas =
						transform[:out].select {
							|out_type|
							! @schema_types.include? "schema/#{out_type}"
						}

					result = [
						missing_input_types,
						missing_input_schemas,
						missing_output_schemas,
					].flatten.empty?

					messages = []

					messages << "incomplete inputs: %s" % [
						missing_input_types.join(", "),
					] unless missing_input_types.empty?

					messages << "missing input schemas: %s" % [
						missing_input_schemas.join(", "),
					] unless missing_input_schemas.empty?

					messages << "missing output schemas: %s" % [
						missing_output_schemas.join(", "),
					] unless missing_output_schemas.empty?

					unless messages.empty?
						logger.debug "rule %s: %s" % [
							transform[:name],
							messages.join("; "),
						]
					end

					result

				end
			]

		num_processed = 0

		transforms_for_pass.each do
			|transform_name, transform|

			used_types =
				transform_loop transform

			missing_types =
				used_types.select {
					|type|
					@incomplete_types.include? type
				}

			raise "Error" unless missing_types.empty?

			if missing_types.empty?
				@remaining_transforms.delete transform_name
				num_processed += 1
			end

		end

		return num_processed

	end

	def transform_loop transform

		rule = @rules[transform[:rule]]

		logger.debug "running transform #{transform[:name]}"
		logger.time "running transform #{transform[:name]}" do

			inputs = get_inputs transform

			inputs.each do
				|input|

				transform_once transform, rule, input

			end

			return []

		end

	end

	def get_inputs transform

		if transform[:matches].empty?
			return [{}]
		end

		inputs_set = Set.new

		transform[:matches].each do
			|match|

			@data.each do
				|id, record|

				next unless id =~ /^#{Regexp.quote match[:type]}\//

				input = {}

				match[:fields].each do
					|field|

					input[field[:as]] =
						record[field[:name]]

				end

				inputs_set << input

			end

		end

		return inputs_set.to_a.sort

	end

	def transform_once transform, rule, input

		used_types = Set.new
		result_str = nil

		begin

			@backend_session.compile_xquery \
				rule[:source],
				rule[:filename]

			result_str =
				@backend_session.run_xquery \
					input \
			do
				|name, args|

				case name

				when "get record by id"
					args["id"] =~ /^([^\/]+)\//
					used_types << $1
					record = @data[args["id"]]
					record ? [ record ] : []

				when "get record by id parts"
					used_types << args["type"]
					id = [ args["type"], *args["id parts"] ].join "/"
					record = @data[id]
					record ? [ record ] : []

				when "search records"
					used_types << args["type"]
					regex = /^#{Regexp.escape args["type"]}\//
					@data \
						.select { |id, record| id =~ regex }
						.sort
						.map { |id, record| record }

				else
					raise "No such function #{name}"

				end

			end

		rescue RuleError => exception

			logger.die "%s:%s:%s %s" % [
				exception.file,
				exception.line,
				exception.column,
				exception.message
			]

		rescue => exception
			logger.error "%s: %s" % [
				exception.class,
				exception.to_s,
			]
			logger.detail exception.backtrace.join("\n")
			FileUtils.touch "#{work_dir}/error-flag"
			raise "error compiling #{rule[:path]}"
		end

		# process output

		result_doms =
			load_data_string result_str

		result_doms.each do
			|item_dom|

			begin

				item_id =
					get_record_id_long \
						@schemas,
						item_dom

			rescue => e

				logger.die "record id error for %s created by %s" % [
					item_dom.name,
					transform_name,
				]

			end

			store_data item_dom

		end

	end

	def store_data item_dom

		# determine id

		item_id =
			get_record_id_long \
				@schemas,
				item_dom

		if @data[item_id]
			raise "duplicate record id #{item_id}"
		end

		# store in memory

		item_xml =
			to_xml_string item_dom

		@data[item_id] =
			item_xml

		# store in filesystem

		item_path =
			"#{output_dir}/data/#{item_id}.xml"

		item_dir =
			File.dirname item_path

		FileUtils.mkdir_p \
			item_dir

		File.open item_path, "w" do
			|file_io|
			file_io.puts item_xml
		end

	end

end
end
end
