chocolatey 'nxlog' do
  action :install
end

service 'nxlog' do
  action :nothing
end

template 'C:\Program Files (x86)\nxlog\conf\nxlog.conf' do
  source "nxlog/win_nxlog.conf.erb"
  notifies :restart, 'service[nxlog]'
end
