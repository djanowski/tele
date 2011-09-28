Gem::Specification.new do |s|
  s.name              = "tele"
  s.version           = "0.1.2"
  s.summary           = "Provisioning at a distance"
  s.description       = "Tele is a small provisioning framework that allows you to run bash scripts on remote servers over SSH."
  s.authors           = ["Damian Janowski", "Michel Martens"]
  s.email             = ["djanowski@dimaion.com", "michel@soveran.com"]
  s.homepage          = "http://github.com/djanowski/tele"

  s.executables.push("tele")

  s.add_dependency("clap")

  s.add_development_dependency("cutest")
  s.add_development_dependency("rake", "0.8.7")

  s.files = Dir[
    "LICENSE",
    "README*",
    "Rakefile",
    "bin/*",
    "templates/.tele/**/*",
    "templates/.tele/recipes/.*",
    "*.gemspec",
    "test/*.*"
  ]
end
