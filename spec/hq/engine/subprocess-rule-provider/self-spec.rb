require "hq/engine/subprocess-rule-provider/self"

module HQ
module Engine

describe SubProcessRuleProvider do

	before do
		@request_rd, @request_wr = IO.pipe
		@response_rd, @response_wr = IO.pipe
	end

	subject do
		SubProcessRuleProvider.new @request_wr, @response_rd
	end

	it "can be instantiated" do
		subject
	end

end

end
end
