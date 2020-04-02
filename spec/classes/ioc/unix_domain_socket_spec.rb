# frozen_string_literal: true

require 'spec_helper'

describe 'epics::ioc::unix_domain_socket' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to create_package('netcat-openbsd').with_ensure('latest') }

      context 'with netcat_openbsd_ensure => netcat_openbsd_version' do
        let(:params) { { 'netcat_openbsd_ensure' => 'netcat_openbsd_version' } }

        it { is_expected.to create_package('netcat-openbsd').with_ensure('netcat_openbsd_version') }
      end
    end
  end
end
