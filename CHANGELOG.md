# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## Unreleased

**Improved**
- Removed calls to systemd::systemctl::daemon_reload as newer versions of puppet-systemd no longer have this class. See [the puppet-systemd README](https://github.com/voxpupuli/puppet-systemd/blob/master/README.md#daemon-reloads) for more information about this removal.
- Changed dependency info to point to new voxpupuli URL of puppet-systemd as the old camptocamp repo no longer exists
- Updated version requirements for puppet-systemd

## [v2.3.0](https://github.com/mark0n/mark0n-epics/tree/2.3.0) (2020-10-20)

**Added**

- Add new parameter procserv_timefmt which configures the time-stamp format used by procServ when printing messages.
- Add new parameters procserv_log_timestamp and procserv_log_timestampfmt which allow date/time to be logged along with procServ's console output. By default log files will now include time-stamps.

**Improved**

- Bump up default core file size to 2 GiB. Most IOCs running on PCs require at least hundreds of MBs, a few GBs isn't unusual. Facilities should consider overriding this value if disk space is very limited or when IOCs consume more memory. Note that procServ versions up to 2.8.0 do not allow this limit to be raised to more than 2 GiB.

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.2.0...2.3.0)

## [v2.2.0](https://github.com/mark0n/mark0n-epics/tree/2.2.0) (2020-06-23)

**Added**

- Add new parameter systemd_notify to epics::ioc which can be used to configure systemd to receive a message from the IOC process when IOC start has completed. Systemd can now be configured to wait until an IOC has started up before starting services that depend on the IOC. In case the IOC crashes during boot the service fails to start. This can be reported by Puppet or IT monitoring tools.

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.1.1...2.2.0)

## [v2.1.1](https://github.com/mark0n/mark0n-epics/tree/2.1.1) (2020-06-16)

**Fixed**

- Do not restart IOC if auto_restart_ioc is set to "false" - even if epics::ioc is notified by an external resource.

**Improved**

- Simplified example for epics::ioc

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.1.0...2.1.1)

## [v2.1.0](https://github.com/mark0n/mark0n-epics/tree/2.1.0) (2020-05-18)

**Added**

- Bring back the abstopdir parameter that had been removed with v2.0.0.

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.0.3...2.1.0)

## [v2.0.3](https://github.com/mark0n/mark0n-epics/tree/2.0.3) (2020-04-10)

**Fixed**

- Ensure environment variables are sorted in output files. This avoids unneeded IOC restarts as a consequence of reorganizing Puppet code.

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.0.2...2.0.3)

## [v2.0.2](https://github.com/mark0n/mark0n-epics/tree/2.0.2) (2020-04-10)

**Improved**

- Simplify example for epics::ioc
- Minor refactoring of epics::carepeater and epics::ioc

**Fixed**

- Start caRepeater service after reloading systemd configuration. In some cases it didn't pick up our changes from the drop-in file.
- Bump up version of puppet-logrotate (it has always been compatible with these newer versions)
- Fix a few brittle unit tests

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.0.1...2.0.2)

## [v2.0.1](https://github.com/mark0n/mark0n-epics/tree/2.0.1) (2020-04-07)

**Fixed**

- Fix Github URLs

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/2.0.0...2.0.1)

## [v2.0.0](https://github.com/mark0n/mark0n-epics/tree/2.0.0) (2020-04-07)

Major parts of the module have been rewritten.

**Features**

- Allow management of Channel Access Repeater.
- Support for Hiera.
- Improved documentation.
- Add unit tests.
- Auto-generate reference documentation using Puppet Strings.
- Fail if requested build/restart behavior is inconsistent.
- Use PID file for notifying logrotate on systems using SysV-style init.
- Allow version of software packages to be specified.
- Leverage types to prevent users from specifying invalid input data. This simplifies the code and leads to easier to understand error messages.

[Full Changelog](https://github.com/mark0n/mark0n-epics/compare/1.3.0...2.0.0)
