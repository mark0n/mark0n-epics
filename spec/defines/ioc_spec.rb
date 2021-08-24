# frozen_string_literal: true

require 'spec_helper'

describe 'epics::ioc' do
  let(:title) { 'testioc' }
  let(:node) { 'test.example.com' }
  let(:params) do
    {}
  end
  let(:pre_condition) { 'package { \'foo\': ensure => latest, tag => \'epics_ioc_pkg\' }' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      ['debian', 'init', 'systemd'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

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
              dropin_file_ensure: 'present',
              user: 'nobody',
            )
          }

          it { is_expected.to create_class('epics::ioc::telnet') }

          it { is_expected.to create_class('epics::ioc::unix_domain_socket') }

          it {
            is_expected.to create_exec("build IOC #{title}").with(
              command: '/usr/bin/make distclean all',
              cwd: "/usr/local/lib/iocapps/#{title}",
              umask: '002',
              unless: '/usr/bin/make CHECK_RELEASE=NO CHECK_RELEASE_NO= --question',
            )
            is_expected.to create_exec("build IOC #{title}").that_requires('Class[epics::ioc::software]')
            is_expected.to create_exec("build IOC #{title}").that_subscribes_to('Package[epics-dev]')
          }

          it {
            is_expected.to create_user("softioc-#{title}").with(
              groups: 'softioc',
              uid: nil,
            )
            is_expected.to create_user("softioc-#{title}").that_comes_before("Service[softioc-#{title}]")
          }

          context 'with manage_autosave_dir => true' do
            let(:params) { { 'manage_autosave_dir' => true } }

            it {
              is_expected.to create_file("/var/lib/softioc-#{title}").with(
                ensure: 'directory',
                owner: "softioc-#{title}",
                group: 'softioc',
                mode: '0775',
              )
              is_expected.to create_file("/var/lib/softioc-#{title}").that_comes_before("Service[softioc-#{title}]")
            }
          end

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
              size: '10M',
              missingok: true,
              ifempty: false,
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

          it {
            is_expected.to create_service("softioc-#{title}").that_subscribes_to('Package[foo]')
          }

          context 'with run_make => false, auto_restart_ioc => false, run_make_after_pkg_update => false' do
            let(:params) { { 'run_make' => false, 'auto_restart_ioc' => false, 'run_make_after_pkg_update' => false } }

            it { is_expected.not_to create_exec("build IOC #{title}") }
            it { is_expected.to create_service("softioc-#{title}").with(restart: '/usr/bin/true') }
          end
          context 'with run_make => false, auto_restart_ioc => false, run_make_after_pkg_update => true' do
            let(:params) { { 'run_make' => false, 'auto_restart_ioc' => false, 'run_make_after_pkg_update' => true } }

            it { is_expected.to compile.and_raise_error(%r{run_make_after_pkg_update => true cannot be combined with run_make => false}) }
          end
          context 'with run_make => false, auto_restart_ioc => true, run_make_after_pkg_update => false' do
            let(:params) { { 'run_make' => false, 'auto_restart_ioc' => true, 'run_make_after_pkg_update' => false } }

            it { is_expected.to compile.and_raise_error(%r{.*auto_restart_ioc => true cannot be combined with run_make => false}) }
          end
          context 'with run_make => false, auto_restart_ioc => true, run_make_after_pkg_update => true' do
            let(:params) { { 'run_make' => false, 'auto_restart_ioc' => true, 'run_make_after_pkg_update' => true } }

            it { is_expected.to compile.and_raise_error(%r{.*(auto_restart_ioc|run_make_after_pkg_update) => true cannot be combined with run_make => false}) }
          end
          context 'with run_make => true, auto_restart_ioc => false, run_make_after_pkg_update => false' do
            let(:params) { { 'run_make' => true, 'auto_restart_ioc' => false, 'run_make_after_pkg_update' => false } }

            it { is_expected.to create_exec("build IOC #{title}") }
            it { is_expected.not_to create_service("softioc-#{title}").that_subscribes_to("Exec[build IOC #{title}]") }
            it { is_expected.not_to create_exec("build IOC #{title}").that_subscribes_to('Package[foo]') }
            it { is_expected.to create_service("softioc-#{title}").with(restart: '/usr/bin/true') }
          end
          context 'with run_make => true, auto_restart_ioc => false, run_make_after_pkg_update => true' do
            let(:params) { { 'run_make' => true, 'auto_restart_ioc' => false, 'run_make_after_pkg_update' => true } }

            it { is_expected.to create_exec("build IOC #{title}") }
            it { is_expected.not_to create_service("softioc-#{title}").that_subscribes_to("Exec[build IOC #{title}]") }
            it { is_expected.to create_exec("build IOC #{title}").that_subscribes_to('Package[foo]') }
            it { is_expected.to create_service("softioc-#{title}").with(restart: '/usr/bin/true') }
          end
          context 'with run_make => true, auto_restart_ioc => true, run_make_after_pkg_update => false' do
            let(:params) { { 'run_make' => true, 'auto_restart_ioc' => true, 'run_make_after_pkg_update' => false } }

            it { is_expected.to create_exec("build IOC #{title}") }
            it { is_expected.to create_service("softioc-#{title}").that_subscribes_to("Exec[build IOC #{title}]") }
            it { is_expected.not_to create_exec("build IOC #{title}").that_subscribes_to('Package[foo]') }
            it { is_expected.not_to create_service("softioc-#{title}").with(restart: '/usr/bin/true') }
          end
          context 'with run_make => true, auto_restart_ioc => true, run_make_after_pkg_update => true' do
            let(:params) { { 'run_make' => true, 'auto_restart_ioc' => true, 'run_make_after_pkg_update' => true } }

            it { is_expected.to create_exec("build IOC #{title}") }
            it { is_expected.to create_service("softioc-#{title}").that_subscribes_to("Exec[build IOC #{title}]") }
            it { is_expected.to create_exec("build IOC #{title}").that_subscribes_to('Package[foo]') }
            it { is_expected.not_to create_service("softioc-#{title}").with(restart: '/usr/bin/true') }
          end

          context 'with abstopdir => \'/arbitrary/directory\'' do
            let(:params) { { 'abstopdir' => '/arbitrary/directory' } }

            it {
              is_expected.to create_exec("build IOC #{title}").with(
                cwd: '/arbitrary/directory',
              )
            }
          end
        end
      end

      ['debian', 'init'].each do |serv_prov|
        context "with service provider #{serv_prov}" do
          let(:facts) do
            os_facts.merge(service_provider: serv_prov)
          end

          it {
            is_expected.to create_file("/etc/iocs/#{title}").with(
              ensure: 'directory',
              group: 'softioc',
            )
          }

          it {
            is_expected.to create_file("/etc/iocs/#{title}/config").with(
              ensure: 'present',
              notify: "Service[softioc-#{title}]",
            )
          }
          it {
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^NAME=#{title}$})
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^PORT=4051$})
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^HOST=#{node}$})
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^USER=softioc-testioc$})
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^CORESIZE=2147483647$})
            is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^CHDIR=/usr/local/lib/iocapps/testioc/iocBoot/ioc\${HOST_ARCH}$})
          }

          it {
            is_expected.to create_exec("create init script for softioc #{title}").with(
              command: "/usr/bin/manage-iocs install #{title}",
              creates: "/etc/init.d/softioc-#{title}",
              require: "File[/etc/iocs/#{title}/config]",
              before: "Service[softioc-#{title}]",
            )
          }

          it {
            is_expected.to create_logrotate__rule("softioc-#{title}").with(
              postrotate: "/bin/kill --signal=HUP `cat /run/softioc-#{title}.pid`",
            )
          }

          it {
            is_expected.to create_service("softioc-#{title}").that_requires(
              [
                'Class[Epics::Carepeater]',
                'Class[Epics::Ioc::Software]',
                "File[/var/log/softioc-#{title}]",
              ],
            )
          }

          context 'with abstopdir => \'/arbitrary/path\'' do
            let(:params) { { 'abstopdir' => '/arbitrary/path' } }

            it {
              is_expected.to create_file("/etc/iocs/#{title}/config").with_content(%r{^CHDIR=/arbitrary/path/iocBoot/ioc\${HOST_ARCH}$})
            }
          end
        end
      end

      context 'with service provider systemd' do
        let(:facts) do
          os_facts.merge(service_provider: 'systemd')
        end

        it {
          # [Unit] section
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^Requires=network.target$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^Wants=caRepeater.service$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^After=([^ ]+ +)*?caRepeater.service( +[^ ]+)*?$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^After=([^ ]+ +)*?network.target( +[^ ]+)*?$})
          # [Service] section
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^Environment="EPICS_IOC_LOG_PORT=7004"$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
            %r{
              ^ExecStart=/usr/bin/procServ\s+--foreground\s+--quiet\s+--chdir=/usr/local/lib/iocapps/testioc/iocBoot/ioc\${HOST_ARCH}\s+
              --ignore=\^C\^D\^\]\s+--coresize=2147483647\s+--restrict\s+--logfile=/var/log/softioc-testioc/procServ.log\s+
              --name\s+testioc\s+--port\s+4051\s+--port\s+unix:/run/softioc-testioc/procServ.sock\s+--timefmt='%%c'\s+--logstamp\s+
              /usr/local/lib/iocapps/testioc/iocBoot/ioc\${HOST_ARCH}/st.cmd$
            }x,
          )
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^Restart=always$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^User=softioc-testioc$})
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^RuntimeDirectory=softioc-testioc$})
          # [Install] section
          is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{^WantedBy=multi-user.target$})
        }
        it { is_expected.to create_systemd__unit_file("softioc-#{title}.service").that_notifies("Service[softioc-#{title}]") }

        it {
          is_expected.to create_logrotate__rule("softioc-#{title}").with(
            postrotate: "/bin/systemctl kill --signal=HUP --kill-who=main softioc-#{title}.service",
          )
        }

        it {
          is_expected.to create_service("softioc-#{title}").that_requires(
            [
              'Class[Epics::Carepeater]',
              'Class[Epics::Ioc::Software]',
              "File[/var/log/softioc-#{title}]",
            ],
          )
        }

        # Ensure "Environment=" lines are sorted to generate stable results
        context 'with environment variables defined' do
          let(:params) { { 'env_vars' => { 'strawberry' => 'red', 'banana' => 'yellow', 'cucumber' => 'green' } } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(%r{Environment="banana=yellow"\nEnvironment="cucumber=green"\nEnvironment="strawberry=red"}m)
          }
        end

        context 'with abstopdir => \'/arbitrary/path\'' do
          let(:params) { { 'abstopdir' => '/arbitrary/path' } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ\s+--foreground\s+--quiet\s+--chdir=/arbitrary/path/iocBoot/ioc\${HOST_ARCH}\s+
                --ignore=\^C\^D\^\]\s+--coresize=2147483647\s+--restrict\s+--logfile=/var/log/softioc-testioc/procServ.log\s+
                --name\s+testioc\s+--port\s+4051\s+--port\s+unix:/run/softioc-testioc/procServ.sock\s+--timefmt='%%c'\s+--logstamp\s+
                /arbitrary/path/iocBoot/ioc\${HOST_ARCH}/st.cmd$
              }x,
            )
          }
        end

        context 'with systemd_notify => false' do
          let(:params) { { 'systemd_notify' => false } }

          it {
            is_expected.not_to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^Type=notify$
              }x,
            )
            is_expected.not_to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^NotifyAccess=all$
              }x,
            )
          }
        end

        context 'with systemd_notify => true' do
          let(:params) { { 'systemd_notify' => true } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^Type=notify$
              }x,
            )
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^NotifyAccess=all$
              }x,
            )
          }
        end

        context 'with procserv_log_timestamp => false' do
          let(:params) { { 'procserv_log_timestamp' => false } }

          it {
            # "ExecStart" line doesn't contain "--logstamp" argument
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ((?!--logstamp).)*$
              }x,
            )
          }
        end

        context "with procserv_log_timestampfmt => 'foo'" do
          let(:params) { { 'procserv_log_timestampfmt' => 'foo' } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ\s+.*?--logstamp='foo'.*$
              }x,
            )
          }
        end
        context "with procserv_log_timestampfmt => '%F %T'" do
          let(:params) { { 'procserv_log_timestampfmt' => '%F %T' } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ\s+.*?--logstamp='%%F\ %%T'.*$
              }x,
            )
          }
        end

        context "with procserv_timefmt => 'foo'" do
          let(:params) { { 'procserv_timefmt' => 'foo' } }

          it {
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ\s+.*?--timefmt='foo'.*$
              }x,
            )
          }
        end
        context "with procserv_timefmt => '%F %T'" do
          let(:params) { { 'procserv_timefmt' => '%F %T' } }

          it {
            # Percent signs are replaced by double percent signs according to https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Specifiers
            is_expected.to create_systemd__unit_file("softioc-#{title}.service").with_content(
              %r{
                ^ExecStart=/usr/bin/procServ\s+.*?--timefmt='%%F\ %%T'.*$
              }x,
            )
          }
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
