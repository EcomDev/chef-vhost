include_attribute 'nginx'

set['nginx']['default_site_enabled'] = false
default['nginx']['sites']['available_dir'] = ::File.join(node['nginx']['dir'], 'sites-available')
default['nginx']['sites']['installed_dir'] = ::File.join(node['nginx']['dir'], 'sites-enabled')

default['vhost']['nginx']['default']['server_names'] = []
default['vhost']['nginx']['default']['listens'] = []
default['vhost']['nginx']['default']['upstreams'] = {}
default['vhost']['nginx']['default']['locations'] = {}
default['vhost']['nginx']['default']['custom_directives'] = []
default['vhost']['nginx']['default']['http_maps'] = {}
default['vhost']['nginx']['default']['ssl'] = nil

default['vhost']['nginx']['default']['document_root'] = nil
default['vhost']['nginx']['default']['custom_error_log'] = nil
default['vhost']['nginx']['default']['custom_access_log'] = nil