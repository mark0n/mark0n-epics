# @summary Install software needed to build and run EPICS IOCs.
#
# This class installs software needed to build and run an EPICS IOC. If IOCs
# are managed by epics::ioc this class is instantiated automatically. You might
# want to include this class directly if your IOCs are managed by other means.
#
# @param ensure_build_essential
#   What state the 'build-essential' package should be in. Valid values include
#   'installed', 'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details.
#
# @param ensure_epics_dev
#   What state the 'epics-dev' package should be in. Valid values include
#   'installed', 'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details.
#
# @param ensure_procserv
#   What state the 'procserv' package should be in. Valid values include
#   'installed', 'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details.
#
# @param ensure_sysv_rc_softioc
#   What state the 'sysv-rc-softioc' package should be in. Valid values include
#   'installed', 'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details. On machines using other service providers like systemd this
#   parameter is ignored.
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