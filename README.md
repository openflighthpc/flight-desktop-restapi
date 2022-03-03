# Flight Desktop RestAPI

A REST API to manage interactive GUI desktop sessions via the `flight-desktop`
tool.

## Overview

Flight Desktop RestAPI is a REST API that in conjunction with [Flight
Desktop Webapp](https://github.com/openflighthpc/flight-desktop-webapp) and
[Flight Desktop](https://github.com/openflighthpc/flight-desktop) provides
browser access to interactive GUI desktop sessions within HPC environments.

## Installation

### Installing with the OpenFlight package repos

Flight Desktop RestAPI is available as part of the *Flight Web Suite*.  This is
the easiest method for installing Flight Desktop RestAPI and all its
dependencies.  It is documented in [the OpenFlight
Documentation](https://use.openflighthpc.org/installing-web-suite/install.html#installing-flight-web-suite).

### Manual Installation

#### Prerequisites

Flight Desktop RestAPI is developed and tested with Ruby version `2.7.1` and
`bundler` `2.1.4`.  Other versions may work but currently are not officially
supported.

Flight Desktop RestAPI requires Flight Desktop which can be installed by following
the [Flight Desktop installation
instructions](https://github.com/openflighthpc/flight-desktop/blob/master/README.md#installation)

#### Install Flight Desktop RestAPI

The following will install from source using `git`.  The `master` branch is
the current development version and may not be appropriate for a production
installation. Instead a tagged version should be checked out.

```
git clone https://github.com/alces-flight/flight-desktop-restapi.git
cd flight-desktop-restapi
git checkout <tag>
bundle config set --local with default
bundle config set --local without development test pry
bundle install
```

The manual installation of Flight Desktop RestAPI comes preconfigured to run in
development mode.  If installing Flight Desktop RestAPI manually for production
usage you will want to follow the instructions to [set the environment
mode](docs/environment-modes.md) to `standalone`.


## Configuration

Flight Desktop RestAPI comes preconfigured to work out of the box without
further configuration.  However, it is likely that you will want to change its
`bind_address` and `base_url`.  Please refer to the [configuration
file](etc/desktop-restapi.yaml) for more details and a full list of
configuration options.

### Environment Modes

If Flight Desktop RestAPI has been installed manually for production usage you
will want to follow the instructions to [set the environment
mode](docs/environment-modes.md) to `standalone`.

## Operation

The service can be started by running:

```
bin/puma
```

See `bin/puma --help` for more help including how to set a pid file and how to
redirect logs.

Typically, the Flight Desktop Webapp is used in conjunction with this API.
However, if you wish to use this API directly, you will want to see the full
[route documentation](docs/routes.md).

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see LICENSE.txt for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under the terms of the Eclipse Public License 2.0 which is available at https://www.eclipse.org/legal/epl-2.0, or alternative license terms made available by Alces Flight Ltd - please direct inquiries about licensing to licensing@alces-flight.com.

FlightDesktopRestAPI is distributed in the hope that it will be useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more details.
