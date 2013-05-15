#!/usr/bin/env ruby

$hq_project_path =
	File.expand_path "..", __FILE__

module ::HQ

	def self.project_param name
		File.read("#{$hq_project_path}/etc/hq-dev/#{name}").strip
	end

	def self.project_include name
		eval progect_param(name)
	end

end

$hq_project_name =
	HQ.project_param "name"

$hq_project_ver =
	HQ.project_param "version"

$hq_project_full =
	HQ.project_param "full-name"

$hq_project_desc =
	HQ.project_param "description"

Dir.mkdir "lib" unless Dir.exist? "lib"

Gem::Specification.new do
	|spec|

	spec.name = $hq_project_name
	spec.version = $hq_project_ver
	spec.platform = Gem::Platform::RUBY
	spec.authors = [ "James Pharaoh" ]
	spec.email = [ "james@phsys.co.uk" ]
	spec.homepage = "https://github.com/jamespharaoh/#{$hq_project_name}"
	spec.summary = $hq_project_full
	spec.description = $hq_project_desc
	spec.required_rubygems_version = ">= 1.3.6"

	spec.rubyforge_project = $hq_project_name

	HQ.project_param("dependencies").split("\n").each do
		|line|

		name, version = line.split " "
		spec.add_dependency name, ">= #{version}"

	end

	HQ.project_param("development-dependencies").split("\n").each do
		|line|

		name, version = line.split " "
		spec.add_development_dependency name, ">= #{version}"

	end

	spec.files = Dir[
		*HQ.project_param("files").split("\n")
	]

	spec.test_files = Dir[
		*HQ.project_param("test-files").split("\n")
	]

	if Dir.exist? "bin"
		spec.executables =
			Dir.new("bin").entries - [ ".", ".." ]
	end

	spec.require_paths = Dir[
		"lib",
	]

end
