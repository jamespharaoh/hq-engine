#!/usr/bin/env ruby

hq_project_name =
	"hq-engine"

hq_project_ver =
	File.read(File.expand_path("../.version", __FILE__))

hq_project_full =
	"HQ engine"

hq_project_desc =
	"HQ transformation engine"

hq_project_dir =
	File.expand_path "..", __FILE__

$LOAD_PATH.unshift "#{hq_project_dir}/ruby" \
	unless $LOAD_PATH.include? "#{hq_project_dir}/ruby"

Gem::Specification.new do
	|spec|

	spec.name = hq_project_name
	spec.version = hq_project_ver
	spec.platform = Gem::Platform::RUBY
	spec.authors = [ "James Pharaoh" ]
	spec.email = [ "james@phsys.co.uk" ]
	spec.homepage = "https://github.com/jamespharaoh/#{hq_project_name}"
	spec.summary = hq_project_full
	spec.description = hq_project_desc
	spec.required_rubygems_version = ">= 1.3.6"

	spec.rubyforge_project = hq_project_name

	spec.add_development_dependency "cucumber", ">= 1.2.1"
	spec.add_development_dependency "rake", ">= 10.0.3"
	spec.add_development_dependency "rspec", ">= 2.12.0"
	spec.add_development_dependency "rspec_junit_formatter"
	spec.add_development_dependency "simplecov"

	spec.files = Dir[
		"lib/**/*.rb",
	]

	spec.test_files = Dir[
		"features/**/*.feature",
		"features/**/*.rb",
		"spec/**/*-spec.rb",
	]

	if Dir.exist? "bin"
		spec.executables =
			Dir.new("bin").entries - [ ".", ".." ]
	end

	spec.require_paths = [ "lib" ]

end
