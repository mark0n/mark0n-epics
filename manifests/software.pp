# This class installs software which are needed in order to build and run a
# soft IOC.
#
class epics::software(
  String $ensure_build_essential,
  String $ensure_epics_dev,
  String $ensure_procserv,
) {
  package { 'build-essential':
    ensure => $ensure_build_essential,
  }

  package { 'epics-dev':
    ensure => $ensure_epics_dev,
  }

  package { 'procserv':
    ensure => $ensure_procserv,
  }

  if $::service_provider == 'init' or $::service_provider == 'debian' {
    package { 'sysv-rc-softioc':
      ensure => installed,
    }
  }
}