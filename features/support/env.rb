require 'tmpdir'
require 'open3'

require 'rspec/expectations'
World(RSpec::Matchers)

YEB_HTTP_PORT = 40666
YEB_HTTPS_PORT = 40667

FileUtils.mkdir_p("tmp/nginx")
NGINX_PREFIX = File.expand_path("tmp/nginx/current")
PRECOMPILED_NGINX_DIR = File.expand_path("tmp/nginx/precompiled")

# install nginx in tmp if not there
unless File.exist?("#{PRECOMPILED_NGINX_DIR}/sbin/nginx")
  FileUtils.rm_rf(NGINX_PREFIX)
  system "scripts/install-nginx.sh #{NGINX_PREFIX}"
  abort "can't compile nginx" unless File.exist?("#{NGINX_PREFIX}/sbin/nginx")
  FileUtils.mv(NGINX_PREFIX, PRECOMPILED_NGINX_DIR)
end

$server_wait_thread = nil

def start_server
  dir = Dir.mktmpdir(nil, "tmp")
  # puts "starting server in #{dir}"
  nginx_dir = "#{dir}/.nginx"
  $YEB_APPS_DIR = dir

  FileUtils.cp_r(PRECOMPILED_NGINX_DIR, nginx_dir)
  FileUtils.rm_rf(NGINX_PREFIX)
  File.symlink(nginx_dir, NGINX_PREFIX)

  env = {
    'YEB_HTTP_PORT' => YEB_HTTP_PORT.to_s,
    'YEB_HTTPS_PORT' => YEB_HTTPS_PORT.to_s,
    'YEB_DIR' => dir,
    'RUBYOPT' => '' # clear what bundler set
  }

  log_file = "#{dir}/yeb.log"
  i, $o, $e, $server_wait_thread = Open3.popen3(env, "bin/yeb")
  # puts "yeb pid: #{$server_wait_thread[:pid]}"

  while $server_wait_thread.alive?
    begin
      socket = TCPSocket.new('localhost', YEB_HTTP_PORT)
      socket.close
      break
    rescue Errno::ECONNREFUSED
      sleep 0.1
    end
  end
end

def stop_server
  ::Process.kill 'TERM', $server_wait_thread[:pid]
end

Before do |scenario|
  start_server
end

After do |scenario|
  stop_server

  if scenario.failed?
    STDOUT.puts $o.read
    STDOUT.puts $e.read
    STDOUT.flush
  else
    FileUtils.rm_rf($YEB_APPS_DIR)
  end
end

# at_exit do
#   ::Process.kill 'TERM', -::Process.getpgrp # terminate all the children
# end
