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

  assert out =~ /staging/
  assert out =~ /cassandra: .*ERROR/
  assert out =~ /redis: .*OK/
end

test "`tele deploy -s production` runs only production recipes" do
  out, err = tele("deploy", "-d", "test/.tele.multi", "-s", "production")

  assert out !~ /staging/

  assert out =~ /production/
  assert out =~ /cassandra: .*ERROR/
  assert out =~ /redis: .*OK/
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

test "Logging to syslog" do
  out, err = tele("deploy", "-d", "test/.tele.simple")

  assert `tail -n 20 /var/log/syslog /var/log/system.log 2>/dev/null`[%r{tele/staging/cassandra.*Can't find Cassandra}]
end

test "`tele tail` shows Tele logs" do
  log = []
  tailing = false

  t = Thread.new do
    Open3.popen3("#{root "bin/tele"} tail") do |_, out, _, _|
      tailing = true
      while line = out.gets
        log << line
      end
    end
  end

  until tailing; end

  tele("deploy", "-d", "test/.tele.simple")

  t.kill

  assert_equal log.size, 1
  assert log[0] =~ %r{staging/cassandra.*Can't find Cassandra}
end

test "`tele foobar` shouts an error" do
  out, err = tele("foobar", "-d", "test/.tele.simple")

  assert err.include?("Error: unrecognized parameter: foobar")
end
