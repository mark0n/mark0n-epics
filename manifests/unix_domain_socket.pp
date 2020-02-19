# This class contains resources which are required when procServ is used with
# Unix domain sockets
#
class epics::unix_domain_socket() {
  package { 'netcat-openbsd':
    ensure => lookup('epics::software::ensure_netcat-openbsd', String, 'first', 'latest'),
  }
}