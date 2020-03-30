# frozen_string_literal: true

require 'spec_helper'

service_providers = ['debian', 'init', 'systemd']

describe 'epics::ioc::software' do
  on_supported_os.each do |os, os_facts|
    service_providers.each do |serv_prov|
      context "on #{os} with service provider #{serv_prov}" do
        let(:facts) do
          os_facts.merge(service_provider: serv_prov)
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_package('build-essential').with(ensure: 'latest') }
        it { is_expected.to contain_package('epics-dev').with(ensure: 'latest') }
        it { is_expected.to contain_package('procserv').with(ensure: 'latest') }

        if ['debian', 'init'].include?(serv_prov)
          it { is_expected.to contain_package('sysv-rc-softioc').with(ensure: 'latest') }
        else
          it { is_expected.not_to contain_package('sysv-rc-softioc') }
        end
      end
    end
  end
end
