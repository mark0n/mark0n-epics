# @summary Install tools to connect to procServ using TCP.
#
# Install telnet to allow IOC engineers to connect to the IOC shell port
# provided by procServ.
#
# @api private
#
class epics::ioc::telnet() {
  include telnet
}