require 'spec_helper'

describe 'vhost::_test_nginx_lwrp' do
  include SpecHelper

  let(:chef_run) do
    ChefSpec::Runner.new(step_into: 'vhost_nginx') do |node|
      stub_include(['vhost::nginx', 'nginx::default'])
      node.set[:_vhost_test][:name] = 'test.dev'
      node.set[:_vhost_test][:action] = :enable
    end
  end

  let (:test_params) { chef_run.node.set[:_php_fpm_test] }

  let (:node) { chef_run.node }

  it 'includes vhost::nginx recipe' do
    expect(converged).to include_recipe('vhost::nginx')
  end

  it 'calls enable nginx vhost resource' do
    expect(converged).to enable_vhost_nginx('test.dev')
  end

  it 'does not enable if already enabled' do
    converge do |node|
      allow(File).to receive(:symlink?)
                     .with(File.join(node['nginx']['dir'], 'sites-enabled', 'test.dev.tld'))
                     .and_return(true)
    end

    expect(converged).not_to run_execute('nxensite test.dev.tld')
  end

  it 'enables a virtual host if it is not enabled' do
    expect(converged).to run_execute('nxensite test.dev.tld')
  end
end