# This class installs software which are needed in order to build and run a
# soft IOC.
#
class epics::software() {
  package { 'build-essential':
    ensure => lookup('epics::software::ensure_build-essential', String, 'first', 'latest'),
  }

  package { 'epics-dev':
    ensure => lookup('epics::software::ensure_epics-dev', String, 'first', 'latest'),
  }

  package { 'procserv':
    ensure => lookup('epics::software::ensure_procserv', String, 'first', 'latest'),
  }
}