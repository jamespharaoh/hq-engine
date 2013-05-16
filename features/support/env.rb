require "hq/cucumber/command"
require "hq/cucumber/temp-dir"

require "hq/engine/engine-script"
require "hq/transform/transform-script"

include HQ

$commands["engine"] = Engine::EngineScript
$commands["transform"] = Transform::TransformScript
