# frozen_string_literal: true

require 'spec_helper'

describe 'epics::ioc' do
  let(:title) { 'namevar' }
  let(:params) do
    {}
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      ['debian', 'init', 'systemd'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          let(:title) { 'testioc' }

          it { is_expected.to compile.with_all_deps }

          it {
            is_expected.to create_class('epics').with(
              iocbase: '/usr/local/lib/iocapps',
              owner: 'root',
              group: 'softioc',
              gid: nil,
            )
          }

          it {
            is_expected.to create_class('epics::ioc::software').with(
              ensure_build_essential: 'latest',
              ensure_epics_dev: 'latest',
              ensure_procserv: 'latest',
              ensure_sysv_rc_softioc: 'latest',
            )
          }

          it {
            is_expected.to create_class('epics::caRepeater').with(
              ensure: 'running',
              enable: true,
              executable: '/usr/bin/caRepeater',
              port: 5065,
              unit_file_ensure: 'present',
              user: 'nobody',
            )
          }

          it { is_expected.to create_class('epics::telnet') }

          it { is_expected.to create_class('epics::unix_domain_socket') }

          it {
            is_expected.to create_exec("build IOC #{title}").with(
              command: '/usr/bin/make distclean all',
              cwd: "/usr/local/lib/iocapps/#{title}",
              umask: '002',
              unless: '/usr/bin/make CHECK_RELEASE=NO CHECK_RELEASE_NO= --question',
            )
          }

          it {
            is_expected.to create_user("softioc-#{title}").with(
              groups: 'softioc',
              uid: nil,
            )
          }

          it {
            is_expected.to create_file("/var/log/softioc-#{title}").with(
              ensure: 'directory',
              owner: "softioc-#{title}",
              group: 'softioc',
              mode: '2755',
            )
          }

          it {
            is_expected.to create_logrotate__rule("softioc-#{title}").with(
              path: "/var/log/softioc-#{title}/procServ.log",
              rotate_every: 'day',
              rotate: 30,
              missingok: true,
              ifempty: false,
              postrotate: "/bin/systemctl kill --signal=HUP --kill-who=main softioc-#{title}.service",
              compress: true,
            )
          }

          it {
            is_expected.to create_service("softioc-#{title}").with(
              ensure: nil,
              enable: nil,
              hasrestart: true,
              hasstatus: true,
              provider: serv_prov,
            )
          }
        end
      end

      ['debian', 'init'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it {
            is_expected.to create_exec("create init script for softioc #{title}").with(
              command: "/usr/bin/manage-iocs install #{title}",
              creates: "/etc/init.d/softioc-#{title}",
            )
          }
        end
      end

      context 'with service provider systemd' do
        let(:facts) do
          os_facts.merge(service_provider: 'systemd')
        end

        it { is_expected.to create_systemd__unit_file("softioc-#{title}.service") }
      end

      context 'with unsupported service provider' do
        let(:facts) do
          os_facts.merge(service_provider: 'unsupported')
        end

        it { is_expected.to compile.and_raise_error(%r{.*doesn't support service provider 'unsupported'.*}) }
      end
    end
  end
end
