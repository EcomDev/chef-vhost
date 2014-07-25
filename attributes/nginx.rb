include_attribute 'nginx'

namespace 'nginx', precedence: set do
  default_site_enabled false
end

namespace 'nginx', 'sites' do
  available_dir ::File.join(node['nginx']['dir'], 'sites-available')
  installed_dir ::File.join(node['nginx']['dir'], 'sites-enabled')
end

namespace 'vhost', 'nginx', 'default' do
  server_names Array.new
  listens Array.new
  upstreams Hash.new
  locations Hash.new
  custom_directives Array.new
  http_maps Hash.new
  ssl nil
  document_root nil
  custom_error_log nil
  custom_access_log nil
end