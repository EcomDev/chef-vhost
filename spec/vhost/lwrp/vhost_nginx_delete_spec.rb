require 'spec_helper'

describe 'vhost::_test_nginx_lwrp' do
  include SpecHelper

  before(:each) do
    allow_recipe('nginx::default','vhost::nginx')
  end

  let(:chef_run) do
    chef_run_proxy.instance(step_into: 'vhost_nginx') do |node|
      node.set[:_vhost_test][:name] = 'test.dev'
      node.set[:_vhost_test][:action] = :delete
    end.converge(described_recipe)
  end

  let (:node) { chef_run.node }

  it 'includes vhost::nginx recipe' do
    expect(chef_run).to include_recipe('vhost::nginx')
  end

  it 'calls delete nginx vhost resource' do
    expect(chef_run).to delete_vhost_nginx('test.dev')
  end

  it 'deletes a configuration file' do
    expect(chef_run).to delete_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
    expect(chef_run).not_to run_execute('nxdissite test.dev.tld')
  end

  it 'disables a virtual host if it is enabled' do
    chef_run_proxy.block(:converge, false) do |chef_run|
      allow(File).to receive(:symlink?)
                     .with(File.join(chef_run.node['nginx']['dir'], 'sites-enabled', 'test.dev.tld'))
                     .and_return(true)
    end

    expect(chef_run).to run_execute('nxdissite test.dev.tld')
  end
end