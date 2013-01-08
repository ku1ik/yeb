require 'httparty'
require 'uri'

Given /^there's no app (.+)$/ do |app_name|
  FileUtils.rm_rf("#{$YEB_APPS_DIR}/#{app_name}")
end

Given /^there's "([^"]+)" app symlinked as "([^"]+)"$/ do |app_name, symlink_name|
  dst = "#{$YEB_APPS_DIR}/#{symlink_name}"
  FileUtils.rm_rf(dst)
  src = File.expand_path("../../../apps/#{app_name}", __FILE__)
  File.symlink(src, dst)
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
end

When /^I request (.+) for .+ time$/ do |url|
  uri = URI(url)
  headers = { 'Host' => uri.host }
  2.times do
    @response = HTTParty.get("http://localhost:#{YEB_HTTP_PORT}#{uri.path}", :headers => headers)
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
