#platform = ubuntu
include_recipe "nginx"
include_recipe "fast-elk::java"

file "/etc/apt/sources.list.d/elasticsearch.list" do
  content "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main"
  notifies :run, "execute[es_gpg]", :immediately
  notifies :run, "execute[apt_update]", :immediately
end

file "/etc/apt/sources.list.d/logstash.list" do
  content "deb http://packages.elasticsearch.org/logstash/1.5/debian stable main"
  notifies :run, "execute[apt_update]", :immediately
end

execute "apt_update" do
  command "apt-get update"
  action :nothing
end

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
    /usr/share/elasticsearch/bin/plugin -install lmenezes/elasticsearch-kopf
  EOF
  action :nothing
end

package "apache2-utils" do
  action :install
  notifies :run, "execute[set_kibana_passwd]", immediately
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

service "nginx" do
  action [:enable, :start]
end

["elasticsearch", "logstash"].each do | s |
  service s do
    action [:enable, :start]
  end
end

#TODO: wait for 10 secs
#curl -X GET 'http://localhost:9200'
#curl 'http://localhost:9200/_search?pretty'
