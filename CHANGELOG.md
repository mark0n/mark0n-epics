# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

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
