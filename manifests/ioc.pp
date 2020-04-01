# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
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

  $abstopdir = "${epics::iocbase}/${name}"
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
    include epics::telnet
  }

  if $enable_unix_domain_socket {
    include epics::unix_domain_socket
  }

  if $run_make {
    exec { "build IOC ${name}":
      command   => '/usr/bin/make distclean all',
      cwd       => $abstopdir,
      umask     => '002',
      unless    => '/usr/bin/make CHECK_RELEASE=NO CHECK_RELEASE_NO= --question',
      require   => Class['epics::ioc::software'],
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

  if defined(Class[epics::carepeater]) {
    $real_systemd_after = $systemd_after << 'caRepeater.service'
    $real_systemd_wants = $systemd_wants << 'caRepeater.service'
  } else {
    $real_systemd_after = $systemd_after
    $real_systemd_wants = $systemd_wants
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

  $service_require = [
    Class["::${module_name}::carepeater"],
    Class['epics::ioc::software'],
    Package['procserv'],
    File["/var/log/softioc-${name}"],
  ]
  $service_require_systemd = $::service_provider ? {
    'systemd' => [Class['systemd::systemctl::daemon_reload']],
    default   => [],
  }

  service { "softioc-${name}":
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    provider   => $::service_provider,
    require    => $service_require + $service_require_systemd,
  }

  if $run_make and $run_make_after_pkg_update {
    Package <| tag == 'epics_ioc_pkg' |> ~> Exec["build IOC ${name}"]
  }

  if $run_make and $auto_restart_ioc {
    Exec["build IOC ${name}"] ~> Service["softioc-${name}"]
  }
}
