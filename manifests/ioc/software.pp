# This class installs software needed to build and run an EPICS IOC. If IOCs
# are managed by epics::ioc this class is instantiated automatically. You might
# want to include this class directly if your IOCs are managed by other means.
#
class epics::ioc::software(
  String $ensure_build_essential,
  String $ensure_epics_dev,
  String $ensure_procserv,
  String $ensure_sysv_rc_softioc,
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
      ensure => $ensure_sysv_rc_softioc,
    }
  }
}