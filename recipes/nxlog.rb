#use the cookbook to get the lates
#we will control the template after that
if !::File.file?('/usr/bin/nxlog')
  include_recipe "nxlog"
end

template "/etc/nxlog/nxlog.conf" do
  notifies :restart, "service[nxlog]"
end

service "nxlog" do
  action [:enable, :start]
  supports :status => true, :restart => true, :reload => true
end


