# This class takes care of all global tasks which are needed in order to run a
# soft IOC. It installs the needed packages and prepares machine-global
# directories and configuration files.
#
class epics(
  Stdlib::Absolutepath $iocbase,
  String               $owner,
  String               $group,
  Optional[Integer]    $gid     = undef,
) {
  group { $group:
    ensure => present,
    gid    => $gid,
  }

  if $::service_provider == 'init' or $::service_provider == 'debian' {
    file { '/etc/default/epics-softioc':
      content => template("${module_name}/etc/default/epics-softioc"),
      owner   => $owner,
      group   => $group,
      mode    => '0644',
    }
  }

  file { '/etc/iocs':
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { $iocbase:
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '2755',
  }
}
