include_recipe 'nginx::default'

file File.join(node['nginx']['dir'], 'conf.d', 'default.conf') do
  action :delete
end
