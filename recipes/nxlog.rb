#use the cookbook to get the lates
#we will control the template after that
if !::File.file?('/usr/bin/nxlog')
  include_recipe "nxlog"
end

group "adm" do
  action :modify
  members "nxlog"
  append true
end

template "/etc/nxlog/nxlog.conf" do
  source "nxlog/nxlog.conf.erb"
  notifies :restart, "service[nxlog]"
end

service "nxlog" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => true
end


