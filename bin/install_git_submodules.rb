require 'rubygems'
Gem.clear_paths

require 'parseconfig'

config = ParseConfig.new("#{ENV['BUILD_DIR']}/.gitmodules")

config.get_params.each do |param|
  next unless param.match(/^submodule/)
  c = config[param]

  github_token = ENV['GITHUB_TOKEN']
  puts "-----> Installing submodule #{c["path"]} #{c["branch"]}"
  branch_flag = c["branch"] ? "-b #{c['branch']}" : ""
  build_path = "#{ENV['BUILD_DIR']}/#{c["path"]}"
  if github_token.nil?
    puts "-----> No GITHUB_TOKEN found, trying regular access"
    `git clone -q --single-branch #{c["url"]} #{branch_flag} #{build_path}`
  else
    fake_url = c["url"].gsub('git@github.com:', "https://{{GITHUB_TOKEN}}:x-oauth-basic@github.com/")
    puts "-----> GITHUB_TOKEN found, adjusting target URL to #{fake_url}"
    url = c["url"].gsub('git@github.com:', "https://#{github_token}:x-oauth-basic@github.com/")
    `git clone -q --single-branch #{url} #{branch_flag} #{build_path}`
  end
  if c.key?("revision")
    puts "       Setting submodule revision to #{c["revision"]}"
    Dir.chdir(build_path) do
      `git reset --hard #{c["revision"]}`
    end
  end

  puts "       Removing submodule git folder"
  `rm -rf #{ENV['BUILD_DIR']}/#{c["path"]}/.git`
end
