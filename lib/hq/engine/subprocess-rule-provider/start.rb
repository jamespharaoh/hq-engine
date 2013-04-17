require "hq/engine/subprocess-rule-provider/rule-provider"

module HQ
module Engine
class SubProcessRuleProvider

	def self.start path_to_server

		ctl_rd, ctl_wr = IO.pipe
		req_rd, req_wr = IO.pipe
		resp_rd, resp_wr = IO.pipe

		File.executable? path_to_server \
			or raise "Not found: #{path_to_server}"

		# TODO why do we fork twice? i don't think we need to...

		outer_pid = fork do

			at_exit { exit! }

			ctl_rd.close

			inner_pid = fork do

				$stdin.reopen req_rd
				$stdout.reopen resp_wr
				#$stderr.reopen "/dev/null", "w"

				req_rd.close
				resp_wr.close

				exec path_to_server

			end

			ctl_wr.puts inner_pid

			exit!

		end

		ctl_wr.close
		req_rd.close
		resp_wr.close

		inner_pid = ctl_rd.gets.strip.to_i
		ctl_rd.close

		Process.wait outer_pid

		at_exit do
			begin
				Process.kill "TERM", inner_pid
			rescue Errno::ESRCH
				# do nothing
			end
		end

		require "hq/engine/subprocess-rule-provider/rule-provider"

		client =
			Client.new \
				req_wr,
				resp_rd

		return client

	end

end
end
end
