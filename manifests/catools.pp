# @summary Install Channel Access command line tools.
#
# Installs the Channel Access command line tools provided by EPICS Base
# (caget, cainfo, camonitor, caput, caRepeater, casw).
#
# @example
#   include epics::catools
#
# @param ensure
#   What state the package should be in. Valid values include 'installed',
#   'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details.
#
class epics::catools(
  String $ensure
) {
  package { 'epics-catools':
    ensure => $ensure,
  }
}