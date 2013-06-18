#
# Cookbook Name:: kyleboon.me
# Recipe:: default
#
# Copyright (C) 2013 YOUR_NAME
# 
# All rights reserved - Do Not Redistribute
#

iptables_rule "port_http"
iptables_rule "port_ssh"


%w(public logs).each do |dir|
  directory "#{node.app.web_dir}/#{dir}" do
    owner 'root'
    mode "0755"
    recursive true
  end
end

template "#{node.nginx.dir}/sites-available/kyleboon.me" do
  source "site.erb"
  mode 0777
  owner 'root'
  group 'root'
end

nginx_site "kyleboon.me"

cookbook_file "#{node.app.web_dir}/public/index.html" do
  source "index.html"
  mode 0755
  owner 'root'
end
