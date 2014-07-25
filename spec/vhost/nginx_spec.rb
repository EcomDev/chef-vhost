require 'spec_helper'

describe 'vhost::nginx' do
  include SpecHelper

  let (:chef_run) do
    chef_run_proxy.instance.converge(described_recipe)
  end

  it 'includes nginx recipe' do
    expect(chef_run).to include_recipe('nginx::default')
  end

  it 'overrides default vhost configuration option' do
    expect(chef_run.node['nginx']['default_site_enabled']).to eq(false)
  end

  it 'deletes nginx default vhost from conf.d directory' do
    expect(chef_run).to delete_file(File.join(chef_run.node['nginx']['dir'], 'conf.d', 'default.conf'))
  end
end