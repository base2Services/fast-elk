#platform = ubuntu
include_recipe "nginx"
include_recipe "fast-elk::java"

#fix up repos
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
    /usr/share/elasticsearch/bin/plugin -install lmenezes/elasticsearch-kopf
  EOF
  action :nothing
end

package "logstash" do
  action :install
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
  url "https://download.elastic.co/kibana/kibana/kibana-4.1.2-linux-x64.tar.gz"
  prefix_root "/opt"
  prefix_home "/opt"
  version "4.1.2"
  #owner apache?
  #notifies :reload, service[nginx]"
end

template "/etc/init.d/kibana4" do
  source "kibana4.init.erb"
  mode '0744'
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
