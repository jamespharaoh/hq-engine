module HQ
module Engine

class RuleError < RuntimeError

	attr_accessor :file
	attr_accessor :line
	attr_accessor :column
	attr_accessor :error

	def initialize file, line, column, error
		super "%s:%s:%s %s" % [
			@file = file,
			@line = line,
			@column = column,
			@error = error,
		]
	end

end

end
end
