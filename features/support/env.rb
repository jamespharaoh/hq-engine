require "hq/cucumber/command"
require "hq/cucumber/temp-dir"

require "hq/transform/transform-script"

include HQ::Transform

$commands["transform"] = TransformScript
