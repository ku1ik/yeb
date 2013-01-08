require 'httparty'
require 'uri'

Given /^there's no app (.+)$/ do |app_name|
  FileUtils.rm_rf("#{$YEB_APPS_DIR}/#{app_name}")
end

Given /^there's "([^"]+)" app symlinked as "([^"]+)"$/ do |app_name, symlink_name|
  @app_dir = "#{$YEB_APPS_DIR}/#{symlink_name}"
  FileUtils.rm_rf(@app_dir)
  src = File.expand_path("../../../apps/#{app_name}", __FILE__)
  FileUtils.rm_rf("#{src}/tmp/restart.txt")
  File.symlink(src, @app_dir)
end

Given /^there's running "([^"]+)" app symlinked as "([^"]+)"$/ do |app_name, symlink_name|
  step %{there's "#{app_name}" app symlinked as "#{symlink_name}"}
  step "I request http://#{symlink_name}.dev/ for the 2nd time"
  step "it doesn't touch spawner"
end

When /^I request ([^\s]+)$/ do |url|
  uri = URI(url)
  headers = { 'Host' => uri.host }
  @response = HTTParty.get("http://localhost:#{YEB_HTTP_PORT}#{uri.path}", :headers => headers)

  @response_bodies ||= []
  @response_bodies << @response.body
end

When /^I request (.+) for .+ time$/ do |url|
  2.times do
    step "I request #{url}"
  end
end

When /^I remove symlink "([^"]+)"$/ do |symlink_name|
  dst = "#{$YEB_APPS_DIR}/#{symlink_name}"
  FileUtils.rm_rf(dst)
end

Then /^I get status (\d+)$/ do |status|
  @response.code.should == status.to_i
end

Then /^it touches spawner$/ do
  @response.headers['x-yeb'].should_not be(nil)
end

Then /^it doesn't touch spawner$/ do
  @response.headers['x-yeb'].should be(nil)
end

Then /^I get text \/(.+)\/$/ do |re|
  @response.body.should =~ Regexp.new(re)
end

When /^I create restart\.txt file in app's tmp dir$/ do
  FileUtils.mkdir_p("#{@app_dir}/tmp")
  FileUtils.touch("#{@app_dir}/tmp/restart.txt")
end

Then /^I get newer app boot timestamp$/ do
  prev_response = @response_bodies[-2]
  last_response = @response_bodies[-1]

  prev_timestamp = prev_response[/timestamp: (\d+\.\d+)/, 1].to_f
  last_timestamp = last_response[/timestamp: (\d+\.\d+)/, 1].to_f

  last_timestamp.should > prev_timestamp
end

Then /^I get the same app boot timestamp$/ do
  prev_response = @response_bodies[-2]
  last_response = @response_bodies[-1]

  prev_timestamp = prev_response[/timestamp: (\d+\.\d+)/, 1].to_f
  last_timestamp = last_response[/timestamp: (\d+\.\d+)/, 1].to_f

  last_timestamp.should == prev_timestamp
end
