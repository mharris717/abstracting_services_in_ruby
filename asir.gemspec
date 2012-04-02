# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asir}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kurt Stephens"]
  s.date = %q{2010-12-10}
  s.description = %q{Abstracting Services in Ruby}
  s.email = %q{ks.ruby@kurtstephens.com}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = [
    "README.textile",
     "Rakefile",
     "VERSION",
     "doc/Rakefile",
     "doc/asir-sequence.pic",
     "doc/asir-sequence.svg",
     "doc/sequence.pic",
     "example/ex01.rb",
     "example/ex02.rb",
     "example/ex03.rb",
     "example/ex04.rb",
     "example/ex05.rb",
     "example/ex06.rb",
     "example/ex07.rb",
     "example/ex08.rb",
     "example/ex09.rb",
     "example/ex10.rb",
     "example/ex11.rb",
     "example/example_helper.rb",
     "example/sample_service.rb",
     "hack_night/README.txt",
     "hack_night/exercise/prob-1.rb",
     "hack_night/exercise/prob-2.rb",
     "hack_night/exercise/prob-3.rb",
     "hack_night/exercise/prob-4.rb",
     "hack_night/exercise/prob-5.rb",
     "hack_night/exercise/prob-6.rb",
     "hack_night/exercise/prob-7.rb",
     "hack_night/solution/math_service.rb",
     "hack_night/solution/prob-1.rb",
     "hack_night/solution/prob-2.rb",
     "hack_night/solution/prob-3.rb",
     "hack_night/solution/prob-4.rb",
     "hack_night/solution/prob-5.rb",
     "hack_night/solution/prob-6.rb",
     "hack_night/solution/prob-7.rb",
     "lib/asir.rb",
     "lib/asir/client.rb",
     "lib/asir/coder.rb",
     "lib/asir/coder/base64.rb",
     "lib/asir/coder/chain.rb",
     "lib/asir/coder/json.rb",
     "lib/asir/coder/marshal.rb",
     "lib/asir/coder/sign.rb",
     "lib/asir/coder/xml.rb",
     "lib/asir/coder/yaml.rb",
     "lib/asir/configuration.rb",
     "lib/asir/initialization.rb",
     "lib/asir/log.rb",
     "lib/asir/object_resolving.rb",
     "lib/asir/request.rb",
     "lib/asir/response.rb",
     "lib/asir/transport.rb",
     "lib/asir/transport/broadcast.rb",
     "lib/asir/transport/fallback.rb",
     "lib/asir/transport/file.rb",
     "lib/asir/transport/http.rb",
     "lib/asir/transport/tcp_socket.rb",
     "spec/example_spec.rb",
     "spec/json_spec.rb",
     "spec/xml_spec.rb"
  ]
  s.homepage = %q{http://github.com/kstephens/abstracting_services_in_ruby}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Abstracting Services in Ruby}
  s.test_files = [
    "spec/example_spec.rb",
     "spec/json_spec.rb",
     "spec/xml_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

