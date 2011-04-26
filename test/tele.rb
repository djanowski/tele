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
  assert out =~ /redis: .*\?/
end

test "`tele deploy` displays layout" do
  out, err = tele("deploy", "-d", "test/.tele")

  assert err.empty?

  parts = out.split("\n\n")

  assert parts[0] =~ /app-1/
  assert parts[0] =~ /redis/
  assert parts[0] =~ /ruby/
  assert parts[0] =~ /unicorn/

  assert parts[1] =~ /app-2/
  assert parts[1] =~ /redis/

  assert parts[2] =~ /app-3/
  assert parts[2] =~ /redis/
  assert parts[2] =~ /ruby/
  assert parts[2] =~ /unicorn/
end

test "`tele deploy` runs recipes" do
  out, err = tele("deploy", "-d", "test/.tele.simple")

  assert out =~ /db-1/
  assert out =~ /cassandra: .*ERROR/
  assert out =~ /redis: .*OK/
end

test "`tele init`" do
  `rm -rf test/tmp`
  `mkdir test/tmp`

  assert !File.exists?("test/tmp/.tele")

  Dir.chdir("test/tmp") do
    out, err = tele("init")

    assert File.exists?(".tele")

    out, err, status = tele("deploy")
    assert status.exitstatus == 0
  end
end

test "Logging to syslog" do
  out, err = tele("status", "-d", "test/.tele.simple")

  assert `tail -n 20 /var/log/syslog /var/log/system.log 2>/dev/null`["Can't find Cassandra"]
end
