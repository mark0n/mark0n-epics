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
      end
    end
  end
end
