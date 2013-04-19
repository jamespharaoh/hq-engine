require "hq/engine/subprocess-rule-provider/session"

module HQ
module Engine
class SubProcessRuleProvider

describe Session do

	context "#compile_xquery" do

		let(:client) { double "client" }

		before do

			dummy_reply = {
				"name" => "ok",
				"arguments" => {
					"result text" => "result text",
				},
			}

			client \
				.stub(:perform)
				.and_return(dummy_reply)

		end

		subject do
			Session.new client, "session id"
		end

		it "performs the request" do

			expected_request = {
				"name" => "compile xquery",
				"arguments" => {
					"session id" => "session id",
					"xquery text" => "xquery text",
					"xquery filename" => "xquery filename",
				},
			}

			client \
				.should_receive(:perform)
				.with(expected_request)

			subject.compile_xquery \
				"xquery text",
				"xquery filename"

		end

		context "on success" do

			it "returns the result text" do

				returned_value =
					subject.compile_xquery \
						"xquery text",
						"xquery filename"

				returned_value.should == "result text"

			end

		end

		context "on error" do

			it "throws an error" do

				error_reply = {
					"name" => "error",
					"arguments" => {
						"file" => "file",
						"line" => "line",
						"column" => "column",
						"error" => "error",
					},
				}

				client \
					.stub(:perform)
					.and_return(error_reply)

				expect {

					subject.compile_xquery \
						"xquery text",
						"xquery filename"

				}.to raise_error(RuleError) {
					|error|

					error.file.should == "file"
					error.line.should == "line"
					error.column.should == "column"
					error.error.should == "error"

					error.message.should == "file:line:column error"

				}

			end

		end

	end

end

end
end
end
