require 'spec_helper'

describe 'vhost::_test_nginx_lwrp' do
  include SpecHelper

  let(:chef_run) do
    ChefSpec::Runner.new(step_into: 'vhost_nginx') do |node|
      stub_include(['vhost::nginx', 'nginx::default'])
      node.set[:_vhost_test][:name] = 'test.dev'
      node.set[:_vhost_test][:action] = :delete
    end
  end

  let (:test_params) { chef_run.node.set[:_vhost_test] }

  let (:node) { chef_run.node }

  it 'includes vhost::nginx recipe' do
    expect(converged).to include_recipe('vhost::nginx')
  end

  it 'calls delete nginx vhost resource' do
    expect(converged).to delete_vhost_nginx('test.dev')
  end

  it 'deletes a configuration file' do
    expect(converged).to delete_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
    expect(converged).not_to run_execute('nxdissite test.dev.tld')
  end

  it 'disables a virtual host if it is enabled' do
    converge do |node|
      allow(File).to receive(:symlink?)
                     .with(File.join(node['nginx']['dir'], 'sites-enabled', 'test.dev.tld'))
                     .and_return(true)
    end

    expect(converged).to run_execute('nxdissite test.dev.tld')
  end
end