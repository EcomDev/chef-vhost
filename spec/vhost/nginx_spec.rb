require 'spec_helper'

describe 'vhost::nginx' do
  include SpecHelper

  let (:chef_run) do
    ChefSpec::Runner.new do
      stub_include
    end
  end

  it 'includes nginx recipe' do
    expect(converged).to include_recipe('nginx::default')
  end

  it 'overrides default vhost configuration option' do
    expect(converged.node['nginx']['default_site_enabled']).to eq(false)
  end

  it 'deletes nginx default vhost from conf.d directory' do
    expect(converged).to delete_file(File.join(converged.node['nginx']['dir'], 'conf.d', 'default.conf'))
  end
end