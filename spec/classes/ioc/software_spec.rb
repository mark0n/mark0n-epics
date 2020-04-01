# frozen_string_literal: true

require 'spec_helper'

describe 'epics::ioc::software' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      ['debian', 'init', 'systemd'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_package('build-essential').with(ensure: 'latest') }
          it { is_expected.to contain_package('epics-dev').with(ensure: 'latest') }
          it { is_expected.to contain_package('procserv').with(ensure: 'latest') }

          context 'installing specific versions' do
            let(:params) do
              {
                ensure_build_essential: 'build_essential_version',
                ensure_epics_dev: 'epics_dev_version',
                ensure_procserv: 'procserv_version',
              }
            end

            it { is_expected.to contain_package('build-essential').with(ensure: 'build_essential_version') }
            it { is_expected.to contain_package('epics-dev').with(ensure: 'epics_dev_version') }
            it { is_expected.to contain_package('procserv').with(ensure: 'procserv_version') }
          end
        end
      end

      ['debian', 'init'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it { is_expected.to contain_package('sysv-rc-softioc').with(ensure: 'latest') }
        end
      end

      context 'with service provider systemd' do
        let(:facts) do
          os_facts.merge(service_provider: 'systemd')
        end

        it { is_expected.not_to contain_package('sysv-rc-softioc') }
      end
    end
  end
end
