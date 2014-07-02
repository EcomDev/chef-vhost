# Vhost cookbook
Wrapper for Vhost creation in different systems

# Requirements
* Virtualbox
* Vagrant
* Vagrant plugins
    * Berkshelf (`vagrant plugin install vagrant-berkshelf --plugin-version 2.0.1`)
    * Hostmanger plugin (`vagrant plugin install hostmanager`) (*nix only)
    * Omnibus installer (`vagrant plugin install vagrant-omnibus`)

# Supported OS
* Ubuntu 12.04, 13.02
* CentOS 6.3, 6.4, 6.5
* Debian 7.4

# LWRPs

* `vhost_nginx`
   * :create - creates a new vhost in nginx
       * available attribute methods:
          * `domain name` - adds a domain to list of server names
          * `domains names` - does the same as domain, but for each array item passed
          * `listen ip_port [, params = [...]]` - adds a new listen directive
          * `upstream name, servers [, custom = []]` - adds a new upstream entry in httpd
          * `location name, directives` - adds a new location entry in server
          * `custom_directive directive` - adds a new custom directive into server itself
          * `http_map var_name, source_var, maps, default = '', hostnames = true` - adds a map directive into httpd
   * :delete - deletes a vhost in nginx available sites
   * :enable - enables a vhost in nginx
   * :disable - disables a vhost in nginx

Example of creating a new vhost:
```ruby
vhost_nginx 'magento.dev' do
    listen '80'
    listen '443', 'ssl'
    
    # adds additional domains besides magento.dev
    domains %w(es.magento.dev en.magento.dev)
    
    upstream 'magento', [{fpm: 'magento'}] # or ['127.0.0.1:9000'] if no php_fpm recipe used
    
    location '= /favicon.ico', :log_not_found => 'off',
                               :access_log => 'off'
                               
    location '= /robots.txt',  :allow => 'all',
                               :log_not_found => 'off',
                               :access_log => 'off'
    
    location '/', :index => 'index.html index.php', 
                  :try_files => '$uri $uri/ @magento',
                  :expires => '30d'
    
    location '@magento', :rewrite => '/ /index.php'
    
    location '~ \.php$', :try_files => '$uri $uri/ @magento',
                         :expires => 'off',
                         :include => 'fastcgi_params',
                         :fastcgi_split_path_info => '^(.+\.php)(/.+)$',
                         :fastcgi_index => 'index.php',
                         :fastcgi_param => {
                            'HTTPS' => '$https if_not_empty',
                            'SCRIPT_FILENAME' => $document_root$fastcgi_script_name                            
                         },
                         :fastcgi_pass => 'magento' # forwards to upstream defined earlier
         
end
```

# Lazy Loading

You don't need to include any of the cookbook recipes, in case if you are using LWRP. It will include related recipe automatically.