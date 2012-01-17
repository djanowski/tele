require "shellwords"
require "open3"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))

def root(*args)
  File.join(ROOT, *args)
end

def tele(*args)
  sh("ruby #{root "bin/tele"} #{Shellwords.join args}")
end

def sh(cmd)
  Open3.capture3(cmd)
end

prepare do
  `rm -rf /tmp/tele`
  `mkdir /tmp/tele`
end

test "`tele deploy` fails without a config" do
  out, err, status = tele("deploy")

  assert err =~ /Couldn't find/
  assert_equal 1, status.exitstatus
end

test "`tele deploy` displays missing recipes" do
  out, err = tele("deploy", "-d", "test/.tele.missing-recipes")

  assert out =~ /db-1/
  assert out =~ /redis.*: .*\?/
end

test "`tele deploy` displays layout" do
  out, err = tele("deploy", "-d", "test/.tele")

  assert err.empty?

  parts = out.split("\n")

  assert parts[0] =~ %r[^app-1/redis]
  assert parts[1] =~ %r[^app-1/ruby]
  assert parts[2] =~ %r[^app-1/unicorn]

  assert parts[3] =~ %r[^app-2/redis]

  assert parts[4] =~ %r[app-3/redis]
  assert parts[5] =~ %r[app-3/ruby]
  assert parts[6] =~ %r[app-3/unicorn]
end

test "`tele deploy` runs recipes" do
  out, err = tele("deploy", "-d", "test/.tele.simple")

  assert out =~ %r[^staging/cassandra.* .*ERROR]
  assert out =~ %r[^staging/redis.* Installed]
  assert out =~ %r[^staging/redis.* .*OK]
end

test "`tele deploy -s production` runs only production recipes" do
  out, err = tele("deploy", "-d", "test/.tele.multi", "-s", "production")

  assert out !~ /staging/

  assert out =~ %r[production/cassandra.*: .*ERROR]
  assert out =~ %r[production/redis.*: .*OK]
end


test "`tele deploy` doesn't run the same recipe twice in a single server" do
  out, err = tele("deploy", "-d", "test/.tele.simple")

  assert_equal File.read("/tmp/tele/touch-count").to_i, 1
end

test "`tele init`" do
  `rm -rf test/tmp`
  `mkdir test/tmp`

  assert !File.exists?("test/tmp/.tele")

  Dir.chdir("test/tmp") do
    out, err = tele("init")

    assert err.empty?

    assert File.exists?(".tele")
    assert File.exists?(".tele/recipes")
    assert !File.exists?(".tele/recipes/.empty")

    out, err, status = tele("deploy")
    assert status.exitstatus == 0
  end
end

test "`tele foobar` shouts an error" do
  out, err = tele("foobar", "-d", "test/.tele.simple")

  assert err.include?("Error: unrecognized parameter: foobar")
end

test "`tele exec` runs commands" do
  out, err = tele("exec", "echo foo", "-d", "test/.tele.simple")

  assert out.include?("staging: foo")
end
