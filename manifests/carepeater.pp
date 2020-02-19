# @summary Install and run the EPICS Channel Access Repeater
#
# Running the Channel Access Repeater is often useful on workstations and other
# computers running multiple Channel Access clients. It forwards beacons to
# multiple clients which allows all clients running on the machine to be
# notified when IOCs are started or stopped. This often leads to faster
# reconnects after IOC restarts. See the
# [Channel Access Reference Manual](https://epics.anl.gov/base/R3-15/7-docs/CAref.html#Repeater)
# for details.
# The epics-catools Debian package automatically enables and starts caRepeater.
# We still provide a way of actively managing it to give admins more
# flexibility.
#
# @example
#   include epics::carepeater
class epics::carepeater(
  Stdlib::Ensure::Service           $ensure,
  Boolean                           $enable,
  String                            $executable,
  Stdlib::Port                      $port,
  Enum['present', 'absent', 'file'] $unit_file_ensure,
  String                            $user,
) {
  include ::epics::catools

  case $::service_provider {
    'systemd': {
      # The epics-catools package already comes with a caRepeater.service file.
      # We only add a drop-in file to allow some configuration.

      systemd::dropin_file { '10-params.conf':
        unit    => 'caRepeater.service',
        content => template("${module_name}/caRepeater/systemd/10-params.conf"),
        notify  => Service['caRepeater'],
      }
    }
    'init', 'debian': {
      file { '/etc/init.d/caRepeater':
        ensure => 'file',
        source => "puppet:///modules/${module_name}/init/caRepeater",
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        notify => Service['caRepeater'],
      }

      file { '/etc/caRepeater.conf':
        ensure  => 'file',
        content => template("${module_name}/caRepeater/init/caRepeater.conf"),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        notify  => Service['caRepeater'],
      }
    }
    default: {
      fail("Module 'epics' doesn't support service provider ${::service_provider}, yet. Pull-requests welcome ;-)")
    }
  }

  service { 'caRepeater':
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    require    => Class['::epics::catools'],
  }

  Service['caRepeater'] -> Service <| tag == 'epics_ioc_service' |>
}
