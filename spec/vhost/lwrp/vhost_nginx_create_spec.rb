require 'spec_helper'

describe 'vhost::_test_nginx_lwrp' do
  include SpecHelper

  before(:each) do
    allow_recipe('nginx::default','vhost::nginx')
  end

  let(:chef_run) do
    chef_run_proxy.instance(step_into: 'vhost_nginx') do |node|
      node.set[:_vhost_test][:name] = 'test.dev'
      node.set[:_vhost_test][:listen] = [
          ['80', %w(default_server backlog=10)]
      ]
      node.set[:_vhost_test][:domain] = %w(en.test.dev www.test.dev)
      node.set[:_vhost_test][:document_root] = '/var/www/test.dev'
    end.converge(described_recipe)
  end

  def test_params(&block)
    chef_run_proxy.before(:converge, false) do |chef_run|
      if block.arity == 1
        block.call(chef_run.node.set[:_vhost_test])
      else
        block.call(chef_run.node.set[:_vhost_test], chef_run.node)
      end
    end
  end

  let (:node) { chef_run.node }

  it 'creates a new fpm pool test' do
    expect(chef_run).to create_vhost_nginx('test.dev')
  end

  it 'includes vhost::nginx recipe' do
    expect(chef_run).to include_recipe('vhost::nginx')
  end

  it 'renders correct nginx vhost file at sites-available' do
    # matches content in _data/vhost._test_nginx_create/default.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('default.cfg'))
  end

  it 'creates correct file permissions for ssl keys' do
    test_params do |params|
      params[:listen] = [
          ['80', %w(default_server backlog=10)],
          ['443', %w(default_server ssl)]
      ]
      params[:ssl] = {
          :public => 'public_key_value',
          :private => 'private_key_value'
      }
    end

    expect(chef_run).to create_directory(File.join(node['nginx']['dir'], 'ssl'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00755)
    expect(chef_run).to create_file(File.join(node['nginx']['dir'], 'ssl', 'test.dev.public.crt'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00640,
                               content: load_expected_file('default_ssl.crt'))

    expect(chef_run).to create_file(File.join(node['nginx']['dir'], 'ssl', 'test.dev.private.key'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00640,
                               content: load_expected_file('default_ssl.key'))

  end

  it 'renders correct nginx vhost file with ssl options at sites-available' do
    test_params do |params|
      params[:listen] = [
          ['80', %w(default_server backlog=10)],
          ['443', %w(default_server ssl)]
      ]

      params[:ssl] = {
          :public => 'public_key_value',
          :private => 'private_key_value'
      }
    end

    # matches content in _data/vhost._test_nginx_create/default_ssl.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('default_ssl.cfg'))
  end

  it 'renders access and error log options' do
    test_params do |params, node|
      node.set[:nginx][:error_log_options] = 'option2' # this one should be rendered
      node.set[:nginx][:access_log_options] = 'option1' # this one should be rendered
    end
    # matches content in _data/vhost._test_nginx_create/log_options.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('log_options.cfg'))
  end

  it 'renders custom access and error logs' do
    test_params do |params, node|
      params[:custom_access_log] = 'off'
      params[:custom_error_log] = '/dev/null'
      node.set[:nginx][:error_log_options] = 'option2' # this one should not be rendered
      node.set[:nginx][:access_log_options] = 'option1' # this one should not be rendered
    end

    # matches content in _data/vhost._test_nginx_create/custom_log.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('custom_log.cfg'))
  end

  it 'renders map variables' do
    test_params do |params|
      params[:http_map] = [
          ['map_variable1', 'http_host', {
              'host.name.com' => 'option2',
              '*.name2.com' => 'option3'
          }, 'option1'],
          ['map_variable2', 'http_user_agent', {
              '~Mozilla Firefox' => 'firefox',
              '~IE' => 'ie'
          }, nil, false]
      ]
    end

    # matches content in _data/vhost._test_nginx_create/map.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('map.cfg'))
  end

  it 'renders upstream' do
    test_params do |params, node|
      params[:upstream] = [
          ['default', [
              '127.0.0.1:9000',
              %w(127.0.0.1:9000 max_conns=10 backup)
          ], {
            :some_custom => 'option',
            :custom => true
          }],
          ['fpm_upstream', [
              {fpm: 'test', params: 'backup'},
              {fpm: 'test', params: ['more_param']},
              {fpm: 'test'}
          ]],
          ['fpm_upstream_tcp', [
              {fpm: 'test_tcp'}
          ]]
      ]
    end

    expect_any_instance_of(Chef::Node).to receive(:shared_data?).with(:resource, :fpm, 'test').at_least(1)
                                          .and_return(true)

    expect_any_instance_of(Chef::Node).to receive(:shared_data?).with(:resource, :fpm, 'test_tcp').at_least(1)
                                          .and_return(true)

    expect_any_instance_of(Chef::Node).to receive(:shared_data).with(:resource, :fpm, 'test').at_least(1)
                                          .and_return(socket_path: '/tmp/php-fpm.sock')

    expect_any_instance_of(Chef::Node).to receive(:shared_data).with(:resource, :fpm, 'test_tcp').at_least(1)
                                          .and_return(ip: '192.168.0.1', port: '9999')

    # matches content in _data/vhost._test_nginx_create/upstream.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('upstream.cfg'))
  end

  it 'renders locations' do
    test_params do |params|
      params[:location] = [
          ['~ /var/', [
              {
                :if => '-d $request_filename',
                :op => [
                    {
                        fastcgi_param: {
                            'MAGE_RUN_CODE' => 'name',
                            'MAGE_RUN_TYPE' => 'type',
                        },
                        fastcgi_pass: 'backend',
                    },
                    'error 505'
                ]
              },
              {
                fastcgi_param: [
                    {
                        :CODE => 'code',
                        :another => 'another'
                    },
                    'more less',
                    'more less'
                ]
              }
          ]],
          ['@magento', {
              :fastcgi_param => {
                  :https => 'on',
                  :path_info => 'path_info'
              }
          }],
          ['@magento2', 'fastcgi_pass magento']
      ]
    end

    # matches content in _data/vhost._test_nginx_create/location.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('location.cfg'))
  end

  it 'renders custom directives' do
    test_params do |params|
      params[:custom_directive] = [
          {gzip: 'on'},
          ['some_directive on;', false]
      ]
    end

    # matches content in _data/vhost._test_nginx_create/custom_directive.cfg.expected
    expect(chef_run).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('custom_directive.cfg'))
  end

  it 'notifies nginx reload if vhost is enabled' do
    chef_run_proxy.block(:converge, false) do |chef_run|
      allow(File).to receive(:symlink?)
                     .with(File.join(chef_run.node['nginx']['dir'], 'sites-enabled', 'test.dev.tld'))
                     .and_return(true)
    end

    file = File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld')

    template = chef_run.template(file)
    expect(template).to notify('service[nginx]').immediately
  end
end