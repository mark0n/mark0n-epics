# @summary Install tools to connect to procServ using Unix domain sockets.
#
# Install netcat to allow IOC engineers to connect to the IOC shell using the
# Unix domain sockets provided by procServ.
#
# @param netcat_openbsd_ensure
#   What state the package should be in. Valid values include 'installed',
#   'latest' as well as a version number of the package. See the
#   [documentation of resource type 'package'](https://puppet.com/docs/puppet/latest/types/package.html#package-attribute-ensure)
#   for details.
#
# @api private
#
class epics::ioc::unix_domain_socket(
  String $netcat_openbsd_ensure,
) {
  package { 'netcat-openbsd':
    ensure => $netcat_openbsd_ensure,
  }
}