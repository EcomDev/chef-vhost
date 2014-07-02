def whyrun_supported?
  true
end

action :create do
  run_context.include_recipe 'vhost::nginx'

  if new_resource.name.match(/^[a-zA-Z0-9\-]+\.[a-zA-Z]+$/)
    unless new_resource.server_names.include?(new_resource.name)
      domains = new_resource.server_names
      domains.unshift(new_resource.name)
      new_resource.server_names(domains)
    end
  end

  resource = Array.new
  variables = new_resource.dump_attribute_values(
    node['vhost']['nginx']['default'],
    :vhost_default
  )

  variables[:upstreams].each_pair do |name, value|
    server_directives = Array.new

    value[:servers].each do  |server|
      server_directive = new_resource.render_upstream_server(server)
      server_directives << server_directive unless server_directive.nil?
    end

    variables[:upstreams][name][:servers] = server_directives
  end

  unless variables[:ssl].nil?
    ssl_dir = ::File.join(node[:nginx][:dir], 'ssl')
    ssl_certificate = ::File.join(ssl_dir, new_resource.name + '.public.crt')
    ssl_certificate_key = ::File.join(ssl_dir, new_resource.name + '.private.key')

    resource <<= directory ssl_dir do
      owner node[:nginx][:user]
      group node[:nginx][:group]
      mode 00755
    end

    resource <<= file ssl_certificate do
      owner node[:nginx][:user]
      group node[:nginx][:group]
      mode 00640
      content "# Managed by Chef. Local changes will be overwritten.
#{new_resource.ssl[:public]}"
    end

    resource <<= file ssl_certificate_key do
      owner node[:nginx][:user]
      group node[:nginx][:group]
      mode 00640
      content "# Managed by Chef. Local changes will be overwritten.
#{new_resource.ssl[:private]}"
    end

    variables[:ssl] = {
        certificate: ssl_certificate,
        certificate_key: ssl_certificate_key
    }
  end

  resource <<= template new_resource.conf_file do
    owner 'root'
    group 'root'
    source 'vhost_nginx.erb'
    cookbook 'vhost'
    mode 00644
    variables(variables)

    if new_resource.enabled?
      notifies :reload, 'service[nginx]', :immediately
    end
  end

  new_resource.update_from_resources(resource)
end

action :delete do
  run_context.include_recipe 'vhost::nginx'

  resource = Array.new

  if new_resource.enabled?
    resource <<= nginx_command('nxdissite')
  end

  resource <<= file new_resource.conf_file do
    action :delete
  end

  new_resource.update_from_resources(resource)
end

action :disable do
  run_context.include_recipe 'vhost::nginx'

  resource = Array.new

  if new_resource.enabled?
    resource <<= nginx_command('nxdissite')
  end

  new_resource.update_from_resources(resource)
end

action :enable do
  run_context.include_recipe 'vhost::nginx'

  resource = Array.new

  unless new_resource.enabled?
    resource <<= nginx_command('nxensite')
  end

  new_resource.update_from_resources(resource)
end

def nginx_command(command, notification = :immediately)
  execute command + ' ' + new_resource.name + '.tld' do
    command "#{node['nginx']['script_dir']}/#{command} #{new_resource.name}.tld"
    notifies :restart, 'service[nginx]', notification
  end
end