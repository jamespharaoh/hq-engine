require "multi_json"

module HQ
module Engine
class SubProcessRuleProvider

	attr_accessor :extensions

	def initialize req_wr, resp_rd

		@state = :error

		@req_wr = req_wr
		@resp_rd = resp_rd

		@state = :open

	end

	def close

		@state == :open \
			or raise "Invalid state #{@state}"

		@state = :error

		@req_wr.close
		@resp_rd.close

		@state = :closed

	end

	def session

		@state == :open \
			or raise "Invalid state #{@state}"

		require "hq/engine/subprocess-rule-provider/session"

		chars = "abcdefghijklmnopqrstuvwxyz"
		session_id = (0...16).map { chars[rand chars.length] }.join("")

		return Session.new self, session_id

	end

	def perform request

		@state == :open \
			or raise "Invalid state #{@state}"

		# send request

		request_string =
			MultiJson.dump request

		@req_wr.puts request_string.length + 1
		@req_wr.puts request_string

		# receive reply

		reply_len = @resp_rd.gets.to_i
		reply_string = @resp_rd.read reply_len

		return MultiJson.load reply_string

	end

end
end
end
