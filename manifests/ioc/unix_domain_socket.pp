# This class contains resources which are required when procServ is used with
# Unix domain sockets
#
class epics::ioc::unix_domain_socket(
  String $netcat_openbsd_ensure,
) {
  package { 'netcat-openbsd':
    ensure => $netcat_openbsd_ensure,
  }
}