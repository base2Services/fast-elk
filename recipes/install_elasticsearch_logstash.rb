#platform = ubuntu
include_recipe "nginx"
include_recipe "fast-elk::java"

#fix up repos
file "/etc/apt/sources.list.d/elasticsearch.list" do
  content "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main"
  notifies :run, "execute[es_gpg]", :immediately
  notifies :run, "execute[apt_update]", :immediately
end

file "/etc/apt/sources.list.d/logstash.list" do
  content "deb http://packages.elastic.co/logstash/2.1/debian stable main"
  notifies :run, "execute[apt_update]", :immediately
end

execute "apt_update" do
  command "apt-get update"
  action :nothing
end

#get keys for apt for logstash and kibana - will need to be notified before apt-get update
execute "es_gpg" do
  command "wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -"
  action :nothing
end

package "elasticsearch" do
  action :install
  notifies :run, "execute[es_plugins]"
end

execute "es_plugins" do
  command <<-EOF
    /usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf
    /usr/share/elasticsearch/bin/plugin install cloud-aws
  EOF
  action :nothing
end

#mkdir
directory node['fast-elk']['es']['data_path'] do
   owner 'elasticsearch'
   group 'elasticsearch'
   mode '0755'
   recursive true
   action :create
end

# set heap size for elasticsearch
template "/etc/init.d/elasticsearch" do
  source "elasticsearch/init.d/elasticsearch.erb"
  owner 'root'
  group 'root'
  mode '0755'
end

template "/etc/elasticsearch/elasticsearch.yml" do
  source "elasticsearch/elasticsearch.yml.erb"
  variables({
    :region => 'ap-southeast-2',
    :ec2_tag => node['fast-elk']['es']['ec2_tag'],
    :ec2_tag_value => node.chef_environment
	})
  notifies :restart, 'service[elasticsearch]'
end

package "logstash" do
  action :install
end


# set heap size for logstash
template "/etc/init.d/logstash" do
  source "logstash/init.d/logstash.erb"
  owner 'root'
  group 'root'
  mode '0755'
end

#logstash templates
#10-iis.conf.erb  10-windows-eventvwr.conf.erb
["01-input", "10-windows-eventvwr", "10-iis", "99-output"].each do | c |
  template "/etc/logstash/conf.d/#{c}.conf" do
    source "logstash/#{c}.conf.erb"
    notifies :restart, 'service[logstash]'
  end
end

package "apache2-utils" do
  action :install
  notifies :run, "execute[set_kibana_passwd]", :immediately
end

execute "set_kibana_passwd" do
  command <<-EOF
    htpasswd -b -c /etc/nginx/htpasswd.users kibanaadmin blahblah
  EOF
end

template "/etc/nginx/sites-available/default" do
  source "ngingx_default_kibana.erb"
  notifies :restart, "service[nginx]"
end

ark "kibana" do
  url "https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz"
  prefix_root "/opt"
  prefix_home "/opt"
  version "4.3.1"
  #owner apache?
  #notifies :reload, service[nginx]"
end

template "/etc/init.d/kibana4" do
  source "kibana4.init.erb"
  mode '0744'
end

template "/opt/kibana/config/kibana.yml" do
  source "kibana.yml.erb"
  notifies :restart, "service[kibana4]"
end

["elasticsearch", "logstash", "nginx", "kibana4"].each do | s |
  service s do
    action [:enable, :start]
    supports :status => true, :restart => true, :reload => true
  end
end


#TODO: wait for 10 secs
#curl -X GET 'http://localhost:9200'
#curl 'http://localhost:9200/_search?pretty'
