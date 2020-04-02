# frozen_string_literal: true

require 'spec_helper'

describe 'epics::catools' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to create_package('epics-catools').with_ensure('latest') }

      context 'with ensure => epics_catools_version' do
        let(:params) { { 'ensure' => 'epics_catools_version' } }

        it { is_expected.to create_package('epics-catools').with_ensure('epics_catools_version') }
      end
    end
  end
end
