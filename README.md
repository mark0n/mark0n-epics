# mark0n-epics - Manage EPICS with Puppet

[![Build Status](https://travis-ci.com/mark0n/mark0n-epics.svg?branch=master)](https://travis-ci.com/mark0n/mark0n-epics)
[![Coverage Status](https://coveralls.io/repos/github/mark0n/mark0n-epics/badge.svg?branch=master)](https://coveralls.io/github/mark0n/mark0n-epics?branch=master)
[![License](https://img.shields.io/github/license/mark0n/mark0n-epics.svg)](https://github.com/mark0n/mark0n-epics/blob/master/LICENSE)
[![Puppet Forge](https://img.shields.io/puppetforge/v/mark0n/epics.svg)](https://forge.puppetlabs.com/mark0n/epics)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/mark0n/epics.svg)](https://forge.puppetlabs.com/mark0n/epics)

This Puppet module manages widely used components of the [Experimental Physics
and Industrial Control System (EPICS)](https://epics-controls.org/). It installs
the required software, configures it and brings up services like control-system
servers (called "Input-Output Controllers", short IOCs, in the EPICS universe)
and the [Channel Access Repeater](https://epics.anl.gov/base/R7-0/3-docs/CAref.html#Repeater)
(a service relaying certain messages sent by EPICS' network protocol to multiple
clients running on the same machine).

This module is used for a wide variety of use cases ranging from configuring
simple test environments in virtual machines to managing hundreds of IOCs for
large particle accelerator facilities. The goal behind this module is to make
simple things simple while at the same time providing enough flexibility to
accommodate one-off requirements. To achieve this, the classes in this module
come with a large number of parameters allowing behavior to be tweaked flexibly
but wherever possible these attributes come with a sensible default inspired by
community best practices so you only need to modify them when you are straying
off the beaten path. Defaults can also be overridden using
[Hiera](https://puppet.com/docs/puppet/latest/hiera.html) which allows
large-scale users to set their own facility-wide default behavior.

## Development

Pull requests are welcome! Here are some steps you can take to avoid
regressions:

### Validate Code and Metadata
```
pdk validate
```

### Run Unit Tests
```
pdk test unit --parallel
```

### Generate Reference Documentation
```
puppet strings generate --format markdown
```
