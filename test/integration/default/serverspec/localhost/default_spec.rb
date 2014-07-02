require 'spec_helper'


describe service('nginx') do
   it { should be_enabled }
   it { should be_running }
end

describe process('nginx') do
  it { should be_running }
end

describe port(80) do
  it { should be_listening.with('tcp') }
end

describe port(443) do
  it { should be_listening.with('tcp') }
end