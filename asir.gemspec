# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{asir}
  s.version = "1.0.1"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kurt Stephens"]
  s.date = %q{2012-04-03}
  s.description = %q{Abstracting Services in Ruby}
  s.email = %q{ks.ruby@kurtstephens.com}
  s.extra_rdoc_files = [
    "README.textile"
  ]
  s.files = `git ls-files`.split("\n")
  s.executables.push(*`git ls-files bin`.split("\n").map{|f| f.gsub('bin/', '')})
  s.homepage = %q{http://github.com/kstephens/abstracting_services_in_ruby}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Abstracting Services in Ruby}
  s.test_files = `git ls-files spec`.split("\n")

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

