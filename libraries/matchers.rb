if defined?(ChefSpec)
  ChefSpec::Runner.define_runner_method(:vhost_nginx)

  def create_vhost_nginx(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:vhost_nginx, :create, resource)
  end

  def delete_vhost_nginx(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:vhost_nginx, :delete, resource)
  end

  def disable_vhost_nginx(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:vhost_nginx, :disable, resource)
  end

  def enable_vhost_nginx(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:vhost_nginx, :enable, resource)
  end
end