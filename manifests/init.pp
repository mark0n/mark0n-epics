# @summary Global configuration for IOCs
#
# This class takes care of all system-wide tasks which are needed in order to
# run a soft IOC. It installs required software and prepares machine-global
# directories and configuration files.
#
# @param iocbase
#   All IOC directories are expected to be located in a central directory. This
#   parameter specifies the path to this base directory. Defaults to
#   '/usr/local/lib/iocapps'.
#
#   Note: Keeping all IOC directories in a central place is required to maintain
#   compatibility with [sysv-rc-softioc](https://github.com/epicsdeb/sysv-rc-softioc).
#   This restriction might be dropped in the future.
#
# @param owner
#   Owner of files/directories shared by all IOC instances (like the log
#   directory). Defaults to 'root'.
#
# @param group
#   Group of files/directories shared by all IOC instances (like the log
#   directory). IOCs are also running under this group. Defaults to 'softioc'.
#
# @param gid
#   Define the group id of the group the IOCs are run as. The gid will be picked
#   automatically if this option is not specified.
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

    file { '/etc/iocs':
      ensure => directory,
      owner  => $owner,
      group  => $group,
    }
  }

  file { $iocbase:
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode   => '2755',
  }
}
