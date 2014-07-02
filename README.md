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
          * `listen ip_or_port [, params = [...]]` - adds a new listen directive
          * `upstream name, servers [, custom = []]` - adds a new upstream entry in httpd  
   * :delete - deletes a vhost in nginx available sites
   * :enable - enables a vhost in nginx
   * :disable - disables a vhost in nginx

Example of creating a new vhost:
```ruby
vhost_nginx 'magento.dev' do
    # adds additional domains besides magento.dev
    domains %w(es.magento.dev en.magento.dev)
    location '/', :try_files => '$uri $uri/ @magento'
    location '~ \.php$', :try_files => '$uri $uri/ @magento'
end
```

# Lazy Loading

You don't need to include any of the cookbook recipes, in case if you are using LWRP. It will include related recipe automatically.