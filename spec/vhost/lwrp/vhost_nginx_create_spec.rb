require 'spec_helper'

describe 'vhost::_test_nginx_lwrp' do
  include SpecHelper

  let(:chef_run) do
    ChefSpec::Runner.new(step_into: 'vhost_nginx') do |node|
      stub_include(['vhost::nginx', 'nginx::default'])
      node.set[:_vhost_test][:name] = 'test.dev'
      node.set[:_vhost_test][:listen] = [
          ['80', %w(default_server backlog=10)]
      ]
      node.set[:_vhost_test][:domain] = %w(en.test.dev www.test.dev)
      node.set[:_vhost_test][:document_root] = '/var/www/test.dev'
    end
  end

  let (:test_params) { chef_run.node.set[:_vhost_test] }

  let (:node) { chef_run.node }

  it 'creates a new fpm pool test' do
    expect(converged).to create_vhost_nginx('test.dev')
  end

  it 'includes vhost::nginx recipe' do
    expect(converged).to include_recipe('vhost::nginx')
  end

  it 'renders correct nginx vhost file at sites-available' do
    # matches content in _data/vhost._test_nginx_create/default.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('default.cfg'))
  end

  it 'creates correct file permissions for ssl keys' do
    test_params[:listen] = [
        ['80', %w(default_server backlog=10)],
        ['443', %w(default_server ssl)]
    ]

    test_params[:ssl] = {
        :public => 'public_key_value',
        :private => 'private_key_value'
    }

    expect(converged).to create_directory(File.join(node['nginx']['dir'], 'ssl'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00755)
    expect(converged).to create_file(File.join(node['nginx']['dir'], 'ssl', 'test.dev.public.crt'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00640,
                               content: load_expected_file('default_ssl.crt'))

    expect(converged).to create_file(File.join(node['nginx']['dir'], 'ssl', 'test.dev.private.key'))
                         .with(owner: node[:nginx][:user],
                               group: node[:nginx][:group],
                               mode: 00640,
                               content: load_expected_file('default_ssl.key'))

  end

  it 'renders correct nginx vhost file with ssl options at sites-available' do
    test_params[:listen] = [
        ['80', %w(default_server backlog=10)],
        ['443', %w(default_server ssl)]
    ]

    test_params[:ssl] = {
        :public => 'public_key_value',
        :private => 'private_key_value'
    }

    # matches content in _data/vhost._test_nginx_create/default_ssl.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('default_ssl.cfg'))
  end

  it 'renders access and error log options' do
    node.set[:nginx][:error_log_options] = 'option2' # this one should be rendered
    node.set[:nginx][:access_log_options] = 'option1' # this one should be rendered

    # matches content in _data/vhost._test_nginx_create/log_options.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('log_options.cfg'))
  end

  it 'renders custom access and error logs' do
    test_params[:custom_access_log] = 'off'
    test_params[:custom_error_log] = '/dev/null'
    node.set[:nginx][:error_log_options] = 'option2' # this one should not be rendered
    node.set[:nginx][:access_log_options] = 'option1' # this one should not be rendered

    # matches content in _data/vhost._test_nginx_create/custom_log.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('custom_log.cfg'))
  end

  it 'renders map variables' do
    test_params[:http_map] = [
        ['map_variable1', 'http_host', {
            'host.name.com' => 'option2',
            '*.name2.com' => 'option3'
        }, 'option1'],
        ['map_variable2', 'http_user_agent', {
            '~Mozilla Firefox' => 'firefox',
            '~IE' => 'ie'
        }, nil, false]
    ]

    # matches content in _data/vhost._test_nginx_create/map.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('map.cfg'))
  end

  it 'renders upstream' do
    test_params[:upstream] = [
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
        ]]
    ]

    allow_any_instance_of(Chef::Resource::LWRPBase).to receive(:fpm_fastcgi_listen)
                                                       .with('test')
                                                       .and_return('unix://tmp/php-fpm.sock')

    # matches content in _data/vhost._test_nginx_create/upstream.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('upstream.cfg'))
  end

  it 'renders locations' do
    test_params[:location] = [
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

    # matches content in _data/vhost._test_nginx_create/location.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('location.cfg'))
  end

  it 'renders custom directives' do
    test_params[:custom_directive] = [
        {gzip: 'on'},
        ['some_directive on;', false]
    ]
    # matches content in _data/vhost._test_nginx_create/custom_directive.cfg.expected
    expect(converged).to render_file(File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld'))
                         .with_content(load_expected_file('custom_directive.cfg'))
  end

  it 'notifies nginx reload if vhost is enabled' do
    converge do |node|
      allow(File).to receive(:symlink?)
                     .with(File.join(node['nginx']['dir'], 'sites-enabled', 'test.dev.tld'))
                     .and_return(true)
    end

    file = File.join(node['nginx']['dir'], 'sites-available', 'test.dev.tld')

    template = converged.template(file)
    expect(template).to notify('service[nginx]').immediately
  end
end