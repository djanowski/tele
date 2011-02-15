Gem::Specification.new do |s|
  s.name              = "tele"
  s.version           = "0.0.1"
  s.summary           = "Provisioning at a distance"
  s.description       = "Tele is a small provisioning framework that allows you to run bash scripts on remote servers over SSH."
  s.authors           = ["Damian Janowski", "Michel Martens"]
  s.email             = ["djanowski@dimaion.com", "michel@soveran.com"]
  s.homepage          = "http://github.com/djanowski/tele"

  s.executables.push("tele")

  s.add_dependency("clap")

  s.files = ["LICENSE", "README", "Rakefile", "bin/tele", "templates/.tele/layout.json", "templates/.tele/ssh_config", "tele.gemspec", "test/tele.rb"]
end
