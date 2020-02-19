# @summary Install Channel Access command line tools.
#
# Installs the Channel Access command line tools provided by EPICS Base
# (caget, cainfo, camonitor, caput, caRepeater, casw).
#
# @example
#   include epics::catools
class epics::catools(
  String $ensure
) {
  package { 'epics-catools':
    ensure => $ensure,
  }
}