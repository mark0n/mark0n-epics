# frozen_string_literal: true

require 'spec_helper'

describe 'epics' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      ['debian', 'init', 'systemd'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_group('softioc').with(
              ensure: 'present',
              gid: nil,
            )
          }

          it {
            is_expected.to create_file('/usr/local/lib/iocapps').with(
              ensure: 'directory',
              owner: 'root',
              group: 'softioc',
              mode: '2755',
            )
          }

          context 'iocbase => /custom/ioc/base/dir' do
            let(:params) { { 'iocbase' => '/custom/ioc/base/dir' } }

            it { is_expected.to create_file('/custom/ioc/base/dir') }
          end

          context 'owner => testowner' do
            let(:params) { { 'owner' => 'testowner' } }

            it { is_expected.to create_file('/usr/local/lib/iocapps').with_owner('testowner') }
          end

          context 'group => testgroup' do
            let(:params) { { 'group' => 'testgroup' } }

            it { is_expected.to create_group('testgroup') }
            it { is_expected.to create_file('/usr/local/lib/iocapps').with_group('testgroup') }
          end

          context 'gid => 123' do
            let(:params) { { 'gid' => 123 } }

            it { is_expected.to create_group('softioc').with_gid(123) }
          end
        end
      end

      ['debian', 'init'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it {
            is_expected.to create_file('/etc/default/epics-softioc').with(
              owner: 'root',
              group: 'softioc',
              mode: '0644',
            )
          }
          it { is_expected.to create_file('/etc/default/epics-softioc').with_content(%r{^SOFTBASE=/usr/local/lib/iocapps$}) }

          it {
            is_expected.to create_file('/etc/iocs').with(
              ensure: 'directory',
              owner: 'root',
              group: 'softioc',
            )
          }

          context 'owner => testowner' do
            let(:params) { { 'owner' => 'testowner' } }

            it { is_expected.to create_file('/etc/default/epics-softioc').with_owner('testowner') }
            it { is_expected.to create_file('/etc/iocs').with_owner('testowner') }
          end

          context 'group => testgroup' do
            let(:params) { { 'group' => 'testgroup' } }

            it { is_expected.to create_file('/etc/default/epics-softioc').with_group('testgroup') }
            it { is_expected.to create_file('/etc/iocs').with_group('testgroup') }
          end
        end
      end
    end
  end
end
