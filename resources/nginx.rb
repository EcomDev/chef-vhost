actions :create, :delete, :enable, :disable

attribute :name, :kind_of => String, :name_attribute => true # Name of the vhost
attribute :server_names, :kind_of => Array, :default => Array.new
attribute :listens, :kind_of => [Array, Symbol], :default => :vhost_default
attribute :upstreams, :kind_of => [Hash, Symbol], :default => :vhost_default
attribute :locations, :kind_of => [Hash, Symbol], :default => :vhost_default
attribute :custom_directives, :kind_of => [Array, Symbol], :default => :vhost_default
attribute :http_maps, :kind_of => [Hash, Symbol], :default => :vhost_default
attribute :document_root, :kind_of => [String, Symbol], :default => :vhost_default
attribute :ssl, :kind_of => [Hash, Symbol], :default => :vhost_default

attribute :custom_error_log, :kind_of => [String, Symbol], :default => :vhost_default
attribute :custom_access_log, :kind_of => [String, Symbol], :default => :vhost_default


public

def initialize(*args)
  super
  @action = :create
end

def domain(domain)
  server_names # initializes default server names
  unless @server_names.include?(domain)
    @server_names << domain
  end
  self
end

def domains(domains)
  domains.each {|domain| domain(domain) }
  self
end

def default_values
  node['vhost']['nginx']['default']
end

def listen(listen, params = Array.new)
  init_default_attribute_value('listens', default_values, :vhost_default)

  @listens << {listen: listen, params: params}
end

def upstream(name, servers, custom = {})
  init_default_attribute_value('upstreams', default_values, :vhost_default)

  @upstreams[name] = {servers: servers, custom: custom}
end

def location (url, directives)
  init_default_attribute_value('locations', default_values, :vhost_default)

  @locations[url.to_s] = directive(directives).split(/\n/)
end

def custom_directive(directive, use_directive = true)
  init_default_attribute_value('custom_directives', default_values, :vhost_default)

  if use_directive
    directive(directive).split(/\n/).each do |v|
      @custom_directives << v
    end
  else
    @custom_directives << directive
  end
end

def http_map(name, source, maps, default = '', hostnames = true)
  init_default_attribute_value('http_maps', default_values, :vhost_default)

  @http_maps[name] = {
      :source => source,
      :maps => maps,
      :default => default,
      :hostnames => hostnames
  }
end

def directive (directive, level = 0, prefix = nil)
  if directive.is_a?(String)
    if directive.empty?
      directive_str = directive
    elsif directive.match(/\n$/)
      directive_str = (' ' * (4 * level) ) + directive
    else
      directive_str = (' ' * (4 * level) ) + (!prefix.nil? ? prefix + ' ': '') + directive + ";\n"
    end
    return directive_str
  elsif directive.is_a?(Array)
    directive_str = ''
    directive.each do |value|
      directive_str += directive(value, level, prefix)
    end
    return directive_str
  elsif directive.is_a?(Hash)
    directive_str = ''
    if directive.key?(:if)
      directive_str += 'if ('
      directive_str += directive[:if]
      directive_str += ') { ' + "\n"
      if directive.key?(:op)
        operation = directive(directive[:op], level+1)
        directive_str += operation unless operation.nil?
      end
      directive_str += '}' + "\n"
    else
      directive.each_pair do |key, value|
        if value.is_a?(String)
          directive_str += directive(key.to_s + ' ' + value, level, prefix)
        else
          directive_str += directive(value, level, prefix.is_a?(String) ? prefix + ' ' + key.to_s : key.to_s)
        end
      end
    end

    return directive_str
  end

  ''
end

def conf_file
  ::File.join(node['nginx']['sites']['available_dir'], name + '.tld')
end

def enabled?
  ::File.symlink?(::File.join(node['nginx']['sites']['installed_dir'], name + '.tld')) ||
      ::File.symlink?(::File.join(node['nginx']['sites']['installed_dir'], '000-' + name + '.tld'))
end

def render_upstream_server(server)
  server_str = nil
  if server.is_a?(Hash) && server.keys.any? {|v| [:fpm, :ip, :port].include?(v.to_sym) }
    if server.key?(:fpm) && node.shared_data?(:resource, :fpm, server[:fpm])
      server_opts = node.shared_data(:resource, :fpm, server[:fpm])
    else
      server_opts = {
        ip: server.key?(:ip) ? server[:ip] : 'localhost',
        port: server.key?(:port) ? server[:port] : '9000',
      }
    end

    if server_opts.key?(:socket_path)
      server_str = 'unix:/' + server_opts[:socket_path]
    else
      server_str = server_opts[:ip] + ':' + server_opts[:port]
    end

    if server.key?(:params)
      if server[:params].is_a?(Array)
        server_str += ' ' + server[:params].join(' ')
      else
        server_str += ' ' + String(server[:params])
      end
    end
  elsif server.is_a?(Array)
    server_str = server.join(' ')
  elsif server.is_a?(String)
    server_str = server
  end

  server_str
end