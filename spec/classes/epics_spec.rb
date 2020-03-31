# frozen_string_literal: true

require 'spec_helper'

service_providers = ['debian', 'init', 'systemd']

describe 'epics' do
  on_supported_os.each do |os, os_facts|
    service_providers.each do |serv_prov|
      context "on #{os} with service provider #{serv_prov}" do
        let(:facts) do
          os_facts.merge(service_provider: serv_prov)
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
