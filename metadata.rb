name             'vhost'
maintainer       'Ivan Chepurnyi'
maintainer_email 'ivan.chepurnyi@ecomdev.org'
license          'GPLv3'
description      'Installs/Configures vhost'
long_description 'Installs/Configures vhost'
version          '0.1.0'

depends 'nginx'
depends 'php_fpm'

%w(ubuntu debian centos).each do |os|
  supports os
end

cookbook = %w(vhost::nginx)

attribute 'nginx/default_site_enabled',
          :display_name => 'Enable default website',
          :description => 'In case you change this value to true, it will create a sites-enabled/000-default file',
          :type => 'bolean',
          :default => false,
          :recipes => cookbook

attribute 'nginx/sites/available_dir',
          :display_name => 'Nginx sites-available directory path',
          :description => 'By default is mapped to nginx[:dir] + \'sites-available\'. It does not affect nxensite and nxdissite bins.',
          :type => 'string',
          :default => '/etc/nginx/sites-available',
          :recipes => cookbook

attribute 'nginx/sites/installed_dir',
          :display_name => 'Nginx sites-available directory path',
          :description => 'By default is mapped to nginx[:dir] + \'sites-available\'. It does not affect nxensite and nxdissite bins.',
          :type => 'string',
          :default => '/etc/nginx/sites-enabled',
          :recipes => cookbook

attribute 'vhost/nginx/default/server_names',
          :display_name => 'Vhost default server names',
          :description => 'Defaults to empty array',
          :type => 'array',
          :default => [],
          :recipes => cookbook

attribute 'vhost/nginx/default/listens',
          :display_name => 'Vhost default listen directives',
          :description => 'Defaults to empty array',
          :type => 'array',
          :default => [],
          :recipes => cookbook

attribute 'vhost/nginx/default/upstreams',
          :display_name => 'Vhost default upstream servers',
          :description => 'Defaults to empty hash',
          :type => 'hash',
          :default => {},
          :recipes => cookbook

attribute 'vhost/nginx/default/locations',
          :display_name => 'Vhost default locations',
          :description => 'Defaults to empty hash',
          :type => 'hash',
          :default => {},
          :recipes => cookbook

attribute 'vhost/nginx/default/custom_directives',
          :display_name => 'Vhost default custom directives',
          :description => 'Defaults to empty array',
          :type => 'array',
          :default => {},
          :recipes => cookbook

attribute 'vhost/nginx/default/http_maps',
          :display_name => 'Vhost default http maps',
          :description => 'Defaults to empty hash',
          :type => 'hash',
          :default => {},
          :recipes => cookbook

attribute 'vhost/nginx/default/ssl',
          :display_name => 'Vhost default ssl options',
          :description => 'Defaults to nil',
          :type => 'hash',
          :default => nil,
          :recipes => cookbook

attribute 'vhost/nginx/default/document_root',
          :display_name => 'Vhost default document root',
          :description => 'Defaults to nil',
          :type => 'string',
          :default => nil,
          :recipes => cookbook

attribute 'vhost/nginx/default/custom_error_log',
          :display_name => 'Vhost default custom error log',
          :description => 'If not specified, it will write logs to node[:nginx][:log_dir]/error.%vhost_name%.log',
          :type => 'string',
          :default => nil,
          :recipes => cookbook

attribute 'vhost/nginx/default/custom_access_log',
          :display_name => 'Vhost default custom access log',
          :description => 'If not specified, it will write logs to node[:nginx][:log_dir]/access.%vhost_name%.log',
          :type => 'string',
          :default => nil,
          :recipes => cookbook
