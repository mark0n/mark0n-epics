# @summary Install and run the EPICS Channel Access Repeater
#
# Running the Channel Access Repeater is often useful on workstations and other
# computers running multiple Channel Access clients. It forwards beacons to
# multiple clients which allows all clients running on the machine to be
# notified when IOCs are started or stopped. This often leads to faster
# reconnects after IOC restarts. See the
# [Channel Access Reference Manual](https://epics.anl.gov/base/R7-0/3-docs/CAref.html#Repeater)
# for details.
#
# In some cases installing the package containing the Channel Access Repeater
# executable might be sufficient to start the Channel Access Repeater service.
# However, this class provides more fine-grained control allowing users to run
# the service on a custom port or under a different user. It can also ensure the
# service is actually running (e.g. if a sysadmin stops it and forgets to start
# it after the maintenance work is finished).
#
# @example Ensure Channel Access Repeater is running
#   include epics::carepeater
#
# @example Ensure Channel Access Repeater is not running
#   class { 'epics::carepeater':
#     ensure => 'stopped',
#     enable => false,
#   }
#
# @example Ensure Channel Access Repeater is running with custom port and user
#   class { 'epics::carepeater':
#     port => 5077,
#     user => 'epics',
#   }
#
# @param ensure
#   Specifies whether the Channel Access Repeater service should be running.
#   Valid values are 'running', 'stopped'. Defaults to 'running'.
#
# @param enable
#   Whether the Channel Access Repeater service should be enabled. This
#   determines if the service is started on system boot. Valid values are true,
#   false. Defaults to true.
#
# @param executable
#   Channel Access Repeater executable. Defaults to '/usr/bin/caRepeater'.
#
# @param port
#   Port that the Channel Access Repeater will listen on. This is setting the
#   value of the `EPICS_CA_REPEATER_PORT` environment variable. Defaults to
#   5065.
#
# @param dropin_file_ensure
#   EPICS Base comes with a systemd service file that allows Channel Access
#   Repeater to be started. However, by itself it doesn't allow its
#   configuration to be tweaked (e.g. custom port, user name etc.). This class
#   thus augments the systemd service file that comes with EPICS with a drop-in
#   file allowing for additional configuration. This parameter controls whether
#   this drop-in file should exist or not. Please refer to the
#   [camptocamp/systemd documentation](https://forge.puppet.com/camptocamp/systemd#drop-in-files)
#   for details. Defaults to 'present'.
#
# @param user
#   User that the Channel Access Repeater service will run as. Defaults to
#   'nobody'.
#
class epics::carepeater(
  Stdlib::Ensure::Service           $ensure,
  Boolean                           $enable,
  String                            $executable,
  Stdlib::Port                      $port,
  Enum['present', 'absent', 'file'] $dropin_file_ensure,
  String                            $user,
) {
  include ::epics::catools

  case $::service_provider {
    'systemd': {
      # The epics-catools package already comes with a caRepeater.service file.
      # We only add a drop-in file to allow some configuration.

      systemd::dropin_file { '10-params.conf':
        ensure  => $dropin_file_ensure,
        unit    => 'caRepeater.service',
        content => template("${module_name}/caRepeater/systemd/10-params.conf"),
        notify  => Service['caRepeater'],
      }

      Class['systemd::systemctl::daemon_reload'] -> Service['caRepeater']
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
      fail("Module '${module_name}' doesn't support service provider '${::service_provider}', yet. Pull-requests welcome ;-)")
    }
  }

  service { 'caRepeater':
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    require    => Class['::epics::catools'],
  }
}
