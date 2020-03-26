# This class takes care of all global tasks which are needed in order to run a
# soft IOC. It installs the needed packages and prepares machine-global
# directories and configuration files.
#
class epics(
  Optional[Integer]    $gid     = undef,
  Stdlib::Absolutepath $iocbase,
) {
  group { 'softioc':
    ensure => present,
    gid    => $gid,
  }

  if $::service_provider == 'init' or $::service_provider == 'debian' {
    file { '/etc/default/epics-softioc':
      content => template("${module_name}/etc/default/epics-softioc"),
      owner   => root,
      group   => root,
      mode    => '0644',
    }
  }

  file { '/etc/iocs':
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
  }

  file { $iocbase:
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
    mode   => '2755',
  }
}