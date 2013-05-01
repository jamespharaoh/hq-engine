require "tempfile"

require "hq/engine/libxmlruby-mixin"

module HQ
module Engine

describe LibXmlRubyMixin do

	subject do
		Class.new {
			include LibXmlRubyMixin
		}.new
	end

	context "#load_data_file" do

		it "reads an XML file into an array of xml nodes" do
			Tempfile.open "hq-engine-spec-" do
				|temp|
				temp.puts "<data><node1/><node2/></data>\n"
				temp.close
				result = subject.load_data_file temp.path
				result.should be_an Array
				result.size.should == 2
				result[0].should be_a XML::Node
				result[1].should be_a XML::Node
				result[0].to_s.should == "<node1/>"
				result[1].to_s.should == "<node2/>"
			end
		end

	end

end

end
end
