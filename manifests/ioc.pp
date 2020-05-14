# @summary Manage an IOC instance.
#
# This type configures an IOC instance. It creates configuration files,
# populates them with the correct values, builds the IOC code (if desired) and
# ensures the IOC instance can be started as a service. The top-level IOC
# directory of the IOC is expected to be $iocbase/<ioc_name> where <ioc_name>
# is the title specified when instantiating the 'epics::ioc' resource.
#
# IOCs are run in [procServ](https://github.com/ralphlange/procServ) to ease
# maintenance. They are started as a system service. On systems that use systemd
# as init system a systemd service file will be created for each IOC process. On
# systems using System-V-style init scripts this module relies on
# sysv-rc-softioc for creating the init scripts. It is possible to transition
# from one init system to another without modifying any Puppet code (just make
# sure to run Puppet after rebooting the machine to give the module the
# opportunity to make the required adjustments).
#
# In contrast to libraries and regular applications which are installed from
# packages, IOCs applications are build on the target machine. This allows IOC
# engineers to fix problems in the EPICS run-time database quickly in the field
# without waiting for a potentially long-running CI pipeline. Of course this
# power comes with the responsibility to push these changes to the version
# control system before they are lost due to a broken drive.
#
# ### Environment Variables
# Some parameters of this class result in environment variables being set.
# Please refer to the following table for a list:
#
# <table>
# <thead>
# <tr>
# <th>Parameter</th>
# <th>Sets Environment Variable</th>
# </tr>
# </thead>
# <tbody>
# <tr>
# <td><code>ca_addr_list</code></td>
# <td><code>EPICS_CA_ADDR_LIST</code></td>
# </tr>
# <tr>
# <td><code>ca_auto_addr_list</code></td>
# <td><code>EPICS_CA_AUTO_ADDR_LIST</code></td>
# </tr>
# <tr>
# <td><code>ca_max_array_bytes</code></td>
# <td><code>EPICS_CA_MAX_ARRAY_BYTES</code></td>
# </tr>
# <tr>
# <td><code>log_port</code></td>
# <td><code>EPICS_IOC_LOG_PORT</code></td>
# </tr>
# <tr>
# <td><code>log_server</code></td>
# <td><code>EPICS_IOC_LOG_INET</code></td>
# </tr>
# <tr>
# <td><code>ca_sec_file</code></td>
# <td><code>EPICS_CA_SEC_FILE</code></td>
# </tr>
# </tbody>
# </table>
# Environment variables that are not on this list can be set using the
# 'env_vars' parameter.
#
# @example Simple
#   file { '/usr/local/lib/iocapps/vacuumioc':
#     source  => 'puppet:///vacuumioc',
#     recurse => true,
#   }
#
#   epics::ioc { 'vacuumioc':
#     subscribe => File['/usr/local/lib/iocapps/vacuumioc'],
#   }
#
# @example Two IOC instances on one machine
#   package { 'epics-autosave-dev':
#     ensure => 'latest',
#     tag    => 'epics_ioc_pkg',
#   }
#
#   # Stick with v4.38 until we found time to test the latest version:
#   package { 'epics-asyn-dev':
#     ensure => '4.38',
#     tag    => 'epics_ioc_pkg',
#   }
#
#   package { 'epics-stream-dev':
#     ensure => 'latest',
#     tag    => 'epics_ioc_pkg',
#   }
#
#   vcsrepo {
#     default:
#       ensure   => 'latest',
#       provider => 'git',
#       group    => 'softioc',;
#
#     '/usr/local/lib/iocapps/llrf':
#       source   => 'git://example.com/llrfioc.git',
#       owner    => 'softioc-llrf',;
#
#     '/usr/local/lib/iocapps/cryo':
#       source   => 'git://example.com/cryo.git',
#       owner    => 'softioc-cryo',;
#   }
#
#   # Settings for all IOC instances (consider putting this into a facility-wide
#   # profile that is applied to all IOC machines):
#   Epics::Ioc {
#     manage_autosave_dir => true,
#     autosave_base_dir   => '/mnt/autosave',
#     log_server          => 'log.example.com',
#   }
#
#   # For this IOC we always want the latest and greatest so we let Puppet
#   # rebuild and restart it whenever new IOC code is pulled from the Git repo
#   # or when a new version of a support package is installed:
#   epics::ioc { 'llrf':
#     console_port => 4051,
#     subscribe    => [
#       Package['epics-autosave-dev'],          # rebuild and restart when package is updated
#       Package['epics-asyn-dev'],              # rebuild and restart when package is updated
#       Vcsrepo['/usr/local/lib/iocapps/llrf'], # rebuild and restart when package is updated
#     ],
#   }
#
#   # For this IOC we can't afford any unplanned downtime so we rebuild but
#   # do not automatically restart this IOC. Rebuilding the IOC ensures that
#   # even in case the IOC crashes we always have a binary that is ready to run
#   # (we don't want to end up starting an IOC executable that has been linked
#   # against an old version of a library which has been removed from the system).
#   epics::ioc { 'cryo':
#     console_port     => 4052,
#     auto_restart_ioc => false,
#     subscribe        => [
#       Package['epics-asyn-dev'],
#       Package['epics-stream-dev'],
#       Vcsrepo['/usr/local/lib/iocapps/cryo'],
#     ],
#   }
#
# @param ensure
#   Ensures the IOC service is running/stopped. Valid values are 'running',
#   'stopped', and undef. If not specified Puppet will not start/stop the IOC
#   service.
#
# @param enable
#   Whether the IOC service should be enabled to start at boot. Valid values are
#   true, false, and undef. If not specified (undefined) Puppet will not
#   enable/disable the IOC service.
#
# @param manage_autosave_dir
#   Whether to automatically populate the `AUTOSAVE_DIR` environment variable.
#   Valid values are true and false. If true the specified directory will be
#   created (users need to ensure the parent directory exists) and permissions
#   will be set appropriately. The `AUTOSAVE_DIR` environment variable will be
#   set to <autosave_base_dir>/softioc-<ioc_name>. Also see the
#   'autosave_base_dir' parameter.
#
# @param auto_restart_ioc
#   Whether to restart the IOC after recompiling. If set to true the IOC will
#   be restarted automatically after recompiling the source code (see
#   `run_make`). This ensures the latest code is being used. Defaults to true.
#
# @param autosave_base_dir
#   The path to the base directory for the EPICS 'autosave' module. Defaults to
#   '/var/lib'.
#
# @param bootdir
#   Path to the directory containing the IOC start script. This path is
#   relative to the IOC's top directory (<iocbase>/<ioc_name>). Defaults to
#   'iocBoot/ioc${{HOST_ARCH}}'.
#
# @param ca_addr_list
#   Allows to configure the `EPICS_CA_ADDR_LIST` environment variable for the
#   IOC. Defaults to undefined (environment variable not set).
#
# @param ca_auto_addr_list
#   Allows to configure the `EPICS_CA_AUTO_ADDR_LIST` environment variable for
#   the IOC. Valid values are true and false. Defaults to undefined (environment
#   variable not set).
#
# @param ca_max_array_bytes
#   Allows to configure the `EPICS_CA_MAX_ARRAY_BYTES` environment variable for
#   the IOC. Defaults to undefined (environment variable not set).
#
# @param startscript
#   Base file name of the IOC start script. Defaults to 'st.cmd'.
#
# @param enable_console_port
#   If set to true (the default) procServ will listen on the port specified by
#   'console_port' for connections to the IOC shell. If this flag is true for at
#   least one IOC telnet is being installed.
#
# @param console_port
#   Specify the port number procServ will listen on for connections to the IOC
#   shell. You can connect to the IOC shell using
#   `telnet localhost <portnumber>`. Defaults to 4051.
#
#   Note that access is not possible if 'enable_console_port' is set to false.
#
# @param enable_unix_domain_socket
#   If set to true (the default) procServ will create a unix domain socket for
#   connections to the IOC shell. If this flag is true for at least one IOC the
#   BSD version of netcat is installed.
#
# @param unix_domain_socket
#   Specify the Unix domain socket file procServ will create for connections
#   to the IOC shell. The file name has to be specified relative to the run-time
#   directory ('/run'). You can connect to the IOC shell using
#   `nc -U <unix_domain_socket>`. Defaults to
#   'softioc-<ioc_name>/procServ.sock'.
#
#   Note that the unix domain socket will not be created if
#   'enable_unix_domain_socket' is set to false.
#
# @param coresize
#   The maximum size (in Bytes) of a core file that will be written in case the
#   IOC crashes. Defaults to 10000000.
#
# @param cfg_append
#   Allows to set additional variables in the IOC's config file in '/etc/iocs/'.
#   This is not used on machines that use systemd.
#
# @param env_vars
#   Specify a hash of environment variables that shall be passed to the IOC.
#   Defaults to {}.
#
# @param log_port
#   Allows to configure the `EPICS_IOC_LOG_PORT` environment variable for the
#   IOC. Defaults to 7004 (the default port used by iocLogServer).
#
# @param log_server
#   Allows to configure the `EPICS_IOC_LOG_INET` environment variable for the
#   IOC. Defaults to undef (environment variable not set).
#
# @param ca_sec_file
#   Allows to configure the `EPICS_CA_SEC_FILE` environment variable for the
#   IOC. Defaults to undef (environment variable not set). Used this with
#   `asSetFilename(${EPICS_CA_SEC_FILE})` in the IOC start-up script.
#
# @param procserv_log_file
#   The log file that procServ uses to log activity on the IOC shell. Defaults
#   to '/var/log/softioc-<ioc_name>/procServ.log'.
#
# @param logrotate_compress
#   Whether to compress the IOC's log files when rotating them. Defaults to
#   true.
#
# @param logrotate_rotate
#   The time in days after which a the log file for the procServ log will be
#   rotated. Defaults to 30.
#
# @param logrotate_size
#   If the log file for the procServ log reaches this size the IOC log will be
#   rotated. Defaults to '10M'.
#
# @param run_make
#   Whether to compile the IOC when its source code changes. If set to true the
#   code in the IOC directory will be compiled automatically by running `make`.
#   This ensures the IOC executable is up to date. Defaults to true.
#
#   Note: This module runs `make --question` to determine whether it needs to
#   rebuild the code by running make. Some Makefiles run a command on every
#   invocation. This can cause `make --question` to always return a non-zero
#   exit code. Beware that this will cause Puppet to rebuild your IOC on every
#   run. Depending on the 'auto_restart_ioc' setting this might also cause the
#   IOC to restart on every Puppet run! Please verify that your Makefiles are
#   behaving correctly to prevent surprises.
#
# @param run_make_after_pkg_update
#   If this option is activated the IOC will be recompiled whenever a 'package'
#   resource tagged as 'epics_ioc_pkg' is refreshed. This can be used to rebuild
#   IOCs when facility-wide installed EPICS modules like autosave are being
#   updated. Defaults to true.
#
# @param uid
#   Defines the system user id the IOC process is supposed to run as. The
#   corresponding user is created automatically. If this is left undefined an
#   arbitrary user id will be picked. This argument is only used if
#   'manage_user' is true.
#
# @param abstopdir
#   Defines the directory where the IOC code is located. This needs to be an
#   absolute path. Defaults to '<iocbase>/<ioc_name>'.
#
#   Note: This parameter is usually only needed in some rare corner cases (for
#   example if the TOP directory of an IOC is not the top directory of the
#   revision-control repository). Avoid its use if you can and clean up your
#   directory layout instead. Think of having all IOC directories in a well
#   known place not as a restriction but as a best practice allowing IOC
#   engineers to quickly find their way around - even if they are not the
#   primary maintainer of that IOC machine. Also note that this parameter cannot
#   be used on machines using System-V-style init scripts due to limitations of
#   the sysv-rc-softioc tools used to manage them.
#
# @param username
#   The user name the IOC will run as. By default 'softioc-<ioc_name>' is being
#   used.
#
# @param manage_user
#   Whether to create the user account the IOC is running as. Set to false to
#   use a user account that is managed by Puppet code outside of this module.
#   Disable if you want multiple IOCs to share the same user account. Defaults
#   to true.
#
# @param systemd_after
#   Ensures the IOC service is started after the specified systemd units have
#   been activated. Please specify an array of strings. Defaults to
#   ['network.target']. This parameter is ignored on systems that are not using
#   systemd.
#
#   Note: This enforces only the correct order. It does not cause the specified
#   targets to be activated. Also see 'systemd_requires'. See the
#   [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#After=)
#   for details.
#
# @param systemd_requires
#   Ensures the specified systemd units are activated when this IOC is started.
#   Defaults to ['network.target']. This parameter is ignored on systems that are
#   not using systemd.
#
#   Note: This only ensures that the required services are started. That
#   generally means that systemd starts them in parallel to the IOC service.
#   Use this parameter together with 'systemd_after' to ensure they are started
#   before the IOC is started. See the
#   [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Requires=)
#   for details.
#
# @param systemd_requires_mounts_for
#   Ensures the specified paths are accessible (e.g. the corresponding file
#   systems are mounted) when this IOC is started. Specify an array of strings.
#   Defaults to []. This parameter is ignored on systems that are not using
#   systemd.
#
#   See the
#   [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#RequiresMountsFor=)
#   for details.
#
# @param systemd_wants
#   Tries to start the specified systemd units when this IOC is started.
#   Defaults to []. This parameter is ignored on systems that are not using
#   systemd.
#
#   Note: systemd will only _try_ to start the services specified here when the
#   IOC service is started. That generally means that systemd starts them in
#   parallel to the IOC service. Use this parameter together with
#   'systemd_after' to ensure systemd has tried starting them _before_ the IOC
#   is started. See the
#   [systemd documentation](https://www.freedesktop.org/software/systemd/man/systemd.unit.html#Wants=)
#   for details.
#
define epics::ioc(
  Optional[Stdlib::Ensure::Service]    $ensure                      = undef,
  Optional[Boolean]                    $enable                      = undef,
  Boolean                              $manage_autosave_dir         = lookup('epics::ioc::manage_autosave_dir', Boolean),
  Boolean                              $auto_restart_ioc            = lookup('epics::ioc::auto_restart_ioc', Boolean),
  String                               $autosave_base_dir           = lookup('epics::ioc::autosave_base_dir', String),
  String                               $bootdir                     = lookup('epics::ioc::bootdir', String),
  Optional[String]                     $ca_addr_list                = undef,
  Optional[Boolean]                    $ca_auto_addr_list           = undef,
  Optional[Integer]                    $ca_max_array_bytes          = undef,
  String                               $startscript                 = lookup('epics::ioc::startscript', String),
  Boolean                              $enable_console_port         = lookup('epics::ioc::enable_console_port', Boolean),
  Stdlib::Port                         $console_port                = lookup('epics::ioc::console_port', Stdlib::Port),
  Boolean                              $enable_unix_domain_socket   = lookup('epics::ioc::enable_unix_domain_socket', Boolean),
  String                               $unix_domain_socket          = "softioc-${name}/procServ.sock",
  Integer                              $coresize                    = lookup('epics::ioc::coresize', Integer),
  Array[String]                        $cfg_append                  = lookup('epics::ioc::cfg_append', Array[String]),
  Hash[String, Data, default, default] $env_vars                    = lookup('epics::ioc::env_vars', Hash[String, Data, default, default]),
  Stdlib::Port                         $log_port                    = lookup('epics::ioc::log_port', Stdlib::Port),
  Optional[Stdlib::Host]               $log_server                  = lookup('epics::ioc::log_server', { 'value_type' => Optional[Stdlib::Host], 'default_value' => undef }),
  Optional[String]                     $ca_sec_file                 = undef,
  Stdlib::Absolutepath                 $procserv_log_file           = "/var/log/softioc-${name}/procServ.log",
  Boolean                              $logrotate_compress          = lookup('epics::ioc::logrotate_compress', Boolean),
  Integer                              $logrotate_rotate            = lookup('epics::ioc::logrotate_rotate', Integer),
  String                               $logrotate_size              = lookup('epics::ioc::logrotate_size', String),
  Boolean                              $run_make                    = lookup('epics::ioc::run_make', Boolean),
  Boolean                              $run_make_after_pkg_update   = lookup('epics::ioc::run_make_after_pkg_update', Boolean),
  Optional[Integer]                    $uid                         = undef,
  String                               $abstopdir                   = "${epics::iocbase}/${name}",
  String                               $username                    = lookup('epics::ioc::username', { 'default_value' => "softioc-${name}" }),
  Boolean                              $manage_user                 = lookup('epics::ioc::manage_user', Boolean),
  Array[String]                        $systemd_after               = lookup('epics::ioc::systemd_after', Array[String]),
  Array[String]                        $systemd_requires            = lookup('epics::ioc::systemd_requires', Array[String]),
  Array[String]                        $systemd_requires_mounts_for = lookup('epics::ioc::systemd_requires_mounts_for', Array[String]),
  Array[String]                        $systemd_wants               = lookup('epics::ioc::systemd_wants', Array[String]),
)
{
  require "::${module_name}"
  include "::${module_name}::ioc::software"
  include "::${module_name}::carepeater"

  $real_systemd_after = $systemd_after << 'caRepeater.service'
  $real_systemd_wants = $systemd_wants << 'caRepeater.service'

  if($bootdir) {
    $absbootdir = "${abstopdir}/${bootdir}"
  } else {
    $absbootdir = $abstopdir
  }

  if $ca_addr_list {
    $env_vars2 = merge($env_vars, {'EPICS_CA_ADDR_LIST' => $ca_addr_list})
  } else {
    $env_vars2 = $env_vars
  }

  if $ca_auto_addr_list {
    $auto_addr_list_str = $ca_auto_addr_list ? {
      true  => 'YES',
      false => 'NO',
    }
    $env_vars3 = merge($env_vars2, {'EPICS_CA_AUTO_ADDR_LIST' => $auto_addr_list_str})
  } else {
    $env_vars3 = $env_vars2
  }

  if $ca_max_array_bytes {
    $env_vars4 = merge($env_vars3, {'EPICS_CA_MAX_ARRAY_BYTES' => $ca_max_array_bytes})
  } else {
    $env_vars4 = $env_vars3
  }

  $env_vars5 = merge($env_vars4, {'EPICS_IOC_LOG_PORT' => $log_port})

  if $log_server {
    $env_vars6 = merge($env_vars5, {'EPICS_IOC_LOG_INET' => $log_server})
  } else {
    $env_vars6 = $env_vars5
  }

  if $ca_sec_file {
    $env_vars7 = merge($env_vars6, {'EPICS_CA_SEC_FILE' => $ca_sec_file})
  } else {
    $env_vars7 = $env_vars6
  }

  if $manage_autosave_dir {
    $real_env_vars = merge($env_vars7, {'AUTOSAVE_DIR' => "${autosave_base_dir}/softioc-${name}"})
  } else {
    $real_env_vars = $env_vars7
  }

  if $enable_console_port {
    include "::${module_name}::ioc::telnet"
  }

  if $enable_unix_domain_socket {
    include "::${module_name}::ioc::unix_domain_socket"
  }

  if $run_make {
    exec { "build IOC ${name}":
      command   => '/usr/bin/make distclean all',
      cwd       => $abstopdir,
      umask     => '002',
      unless    => '/usr/bin/make CHECK_RELEASE=NO CHECK_RELEASE_NO= --question',
      require   => Class["::${module_name}::ioc::software"],
      subscribe => Package['epics-dev'],
    }
  }

  if $manage_user {
    user { $username:
      comment => "${name} IOC",
      home    => "/epics/iocs/${name}",
      groups  => 'softioc',
      uid     => $uid,
      before  => Service["softioc-${name}"],
    }
  }

  if($manage_autosave_dir) {
    file { "${autosave_base_dir}/softioc-${name}":
      ensure => directory,
      owner  => $username,
      group  => 'softioc',
      mode   => '0775',
      before => Service["softioc-${name}"],
    }
  }

  case $::service_provider {
    'systemd': {
      $absstartscript = "${absbootdir}/${startscript}"

      systemd::unit_file { "softioc-${name}.service":
        content => template("${module_name}/etc/systemd/system/ioc.service"),
        notify  => Service["softioc-${name}"],
      }

      $postrotate = "/bin/systemctl kill --signal=HUP --kill-who=main softioc-${name}.service"
    }
    'init', 'debian': {
      file { "/etc/iocs/${name}":
        ensure => directory,
        group  => 'softioc',
      }

      file { "/etc/iocs/${name}/config":
        ensure  => present,
        content => template("${module_name}/etc/iocs/ioc_config"),
        notify  => Service["softioc-${name}"],
      }

      exec { "create init script for softioc ${name}":
        command => "/usr/bin/manage-iocs install ${name}",
        require => File["/etc/iocs/${name}/config"],
        creates => "/etc/init.d/softioc-${name}",
        before  => Service["softioc-${name}"],
      }

      $postrotate = "/bin/kill --signal=HUP `cat /run/softioc-${name}.pid`"
    }
    default: {
      fail("Module '${module_name}' doesn't support service provider '${::service_provider}', yet. Pull-requests welcome ;-)")
    }
  }

  file { "/var/log/softioc-${name}":
    ensure => directory,
    owner  => $username,
    group  => 'softioc',
    mode   => '2755',
  }

  logrotate::rule { "softioc-${name}":
    path         => $procserv_log_file,
    rotate_every => 'day',
    rotate       => $logrotate_rotate,
    size         => $logrotate_size,
    missingok    => true,
    ifempty      => false,
    postrotate   => $postrotate,
    compress     => $logrotate_compress,
  }

  service { "softioc-${name}":
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    provider   => $::service_provider,
    require    => [
      Class["::${module_name}::carepeater"],
      Class["::${module_name}::ioc::software"],
      File["/var/log/softioc-${name}"],
    ],
  }
  if $::service_provider == 'systemd' {
    Class['systemd::systemctl::daemon_reload'] -> Service["softioc-${name}"]
  }

  if $run_make and $run_make_after_pkg_update {
    Package <| tag == 'epics_ioc_pkg' |> ~> Exec["build IOC ${name}"]
  } elsif !$run_make and $run_make_after_pkg_update {
    fail("Module '${module_name}': run_make_after_pkg_update => true cannot be combined with run_make => false")
  }

  if $run_make and $auto_restart_ioc {
    Exec["build IOC ${name}"] ~> Service["softioc-${name}"]
  } elsif !$run_make and $auto_restart_ioc {
    fail("Module '${module_name}': auto_restart_ioc => true cannot be combined with run_make => false")
  }
}
