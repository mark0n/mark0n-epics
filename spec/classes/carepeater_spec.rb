# frozen_string_literal: true

require 'spec_helper'

describe 'epics::carepeater' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      ['debian', 'init', 'systemd'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to create_class('epics::catools').with_ensure('latest') }

          it {
            is_expected.to create_service('caRepeater').with(
              ensure: 'running',
              enable: true,
              hasrestart: true,
            )
            is_expected.to create_service('caRepeater').that_requires('Class[epics::catools]')
          }

          context 'with ensure => stopped' do
            let(:params) { { 'ensure' => 'stopped' } }

            it { is_expected.to create_service('caRepeater').with_ensure('stopped') }
          end

          context 'with enable => false' do
            let(:params) { { 'enable' => false } }

            it { is_expected.to create_service('caRepeater').with_enable(false) }
          end
        end
      end

      ['debian', 'init'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it {
            is_expected.to create_file('/etc/init.d/caRepeater').with(
              ensure: 'file',
              source: 'puppet:///modules/epics/init/caRepeater',
              owner: 'root',
              group: 'root',
              mode: '0755',
            )
            is_expected.to create_file('/etc/init.d/caRepeater').that_notifies('Service[caRepeater]')
          }

          it {
            is_expected.to create_file('/etc/caRepeater.conf').with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0755',
            )
            is_expected.to create_file('/etc/caRepeater.conf').that_notifies('Service[caRepeater]')
          }
          it {
            is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^EXECUTABLE=/usr/bin/caRepeater$})
            is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^EPICS_CA_REPEATER_PORT=5065$})
            is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^USER=nobody$})
          }

          context 'with executable => /path/to/customCaRepeater' do
            let(:params) { { 'executable' => '/path/to/customCaRepeater' } }

            it { is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^EXECUTABLE=/path/to/customCaRepeater$}) }
          end

          context 'with port => 2345' do
            let(:params) { { 'port' => 2345 } }

            it { is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^EPICS_CA_REPEATER_PORT=2345$}) }
          end

          context 'with user => somebody' do
            let(:params) { { 'user' => 'somebody' } }

            it { is_expected.to create_file('/etc/caRepeater.conf').with_content(%r{^USER=somebody$}) }
          end
        end
      end

      context 'with service provider systemd' do
        let(:facts) do
          os_facts.merge(service_provider: 'systemd')
        end

        it { is_expected.to create_systemd__dropin_file('10-params.conf').with_unit('caRepeater.service') }
        it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^ExecStart=$}) }
        it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^ExecStart=/usr/bin/caRepeater$}) }
        it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^Environment=EPICS_CA_REPEATER_PORT=5065$}) }
        it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^User=nobody$}) }

        context 'with ensure => stopped' do
          let(:params) { { 'ensure' => 'stopped' } }

          it { is_expected.to create_service('caRepeater').with_ensure('stopped') }
        end

        context 'with enable => false' do
          let(:params) { { 'enable' => false } }

          it { is_expected.to create_service('caRepeater').with_enable(false) }
        end

        context 'with executable => /path/to/customCaRepeater' do
          let(:params) { { 'executable' => '/path/to/customCaRepeater' } }

          it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^ExecStart=/path/to/customCaRepeater$}) }
        end

        context 'with port => 2345' do
          let(:params) { { 'port' => 2345 } }

          it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^Environment=EPICS_CA_REPEATER_PORT=2345$}) }
        end

        context 'with dropin_file_ensure => absent' do
          let(:params) { { 'dropin_file_ensure' => 'absent' } }

          it { is_expected.to create_systemd__dropin_file('10-params.conf').with_ensure('absent') }
        end

        context 'with user => somebody' do
          let(:params) { { 'user' => 'somebody' } }

          it { is_expected.to create_systemd__dropin_file('10-params.conf').with_content(%r{^User=somebody$}) }
        end
      end

      context 'with unsupported service provider' do
        let(:facts) do
          os_facts.merge(service_provider: 'unsupported')
        end

        it { is_expected.to compile.and_raise_error(%r{doesn't support service provider 'unsupported'}) }
      end
    end
  end
end
