# Absinthe.Phoenix

[![Build Status](https://github.com/absinthe-graphql/absinthe_phoenix/workflows/CI/badge.svg)](https://github.com/absinthe-graphql/absinthe_phoenix/actions?query=workflow%3ACI)
[![Version](https://img.shields.io/hexpm/v/absinthe_phoenix.svg)](https://hex.pm/packages/absinthe_phoenix)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/absinthe_phoenix/)
[![Download](https://img.shields.io/hexpm/dt/absinthe_phoenix.svg)](https://hex.pm/packages/absinthe_phoenix)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Last Updated](https://img.shields.io/github/last-commit/absinthe-graphql/absinthe_phoenix.svg)](https://github.com/absinthe-graphql/absinthe_phoenix/commits/master)

This package integrates Absinthe subscriptions with Phoenix, so that you can use subscriptions via websockets.

For getting started guides on subscriptions see: https://hexdocs.pm/absinthe/subscriptions.html

For getting started guides on server side rendering see: https://hexdocs.pm/absinthe/subscriptions.html

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe_phoenix):

For Phoenix 1.4, see the v1.5 branch: https://github.com/absinthe-graphql/absinthe_phoenix/tree/v1.5

### Phoenix 1.5

```elixir
def deps do
  [
    {:absinthe_phoenix, "~> 2.0.0"}
  ]
end
```

Note: Absinthe.Phoenix requires Elixir 1.11 or higher.

## Upgrading

See [CHANGELOG](./CHANGELOG.md) for upgrade steps between versions.

You may want to look for the specific upgrade guide in the [Absinthe documentation](https://hexdocs.pm/absinthe).

## Documentation

See "Usage," below, for basic usage information and links to specific resources.

- [Absinthe.Phoenix hexdocs](https://hexdocs.pm/absinthe_phoenix).
- For the tutorial, guides, and general information about Absinthe-related
  projects, see [http://absinthe-graphql.org](http://absinthe-graphql.org).

## Related Projects

See the [GitHub organization](https://github.com/absinthe-graphql).

## Usage

You need to have a working Phoenix PubSub configured. Here is what the default looks like if you create a new Phoenix project:

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ... other config
  pubsub_server: MyApp.PubSub
```

In your application supervisor add a line AFTER your existing endpoint supervision
line:

```elixir
[
  # other children ...
  MyAppWeb.Endpoint, # this line should already exist
  {Absinthe.Subscription, pubsub: MyAppWeb.Endpoint}, # add this line
  # other children ...
]
```

Where `MyAppWeb.Endpoint` is the name of your application's phoenix endpoint.

Other options include:

* pool_size - Number of processes created to handle incoming messages concurrently on the current node. Default: `System.schedulers_online() * 2`
* compress_registry? - Whether the underlying registry should be compressed. Default: `true`
* async - Whether the each process above should handle the message in-process (`false`) or create a new process to do so (`true`).  Default: `true`
* registry_partition_strategy - Partition the registry by `:pid` or by `:key`. `:key` is only supported in Elixir 1.19 and up. Default: `:pid`

In your `MyAppWeb.Endpoint` module add:

```elixir
use Absinthe.Phoenix.Endpoint
```

In your socket add:

```elixir
use Absinthe.Phoenix.Socket,
  schema: MyAppWeb.Schema
```

Where `MyAppWeb.Schema` is the name of your Absinthe schema module.

That is all that's required for setup on the server.

For client side guidance see the guides.

## GraphiQL Usage

From within GraphiQL:
To use Absinthe.Phoenix from within GraphiQL, you need to tell GraphiQL about your websocket endpoint.

```elixir
forward "/graphiql", Absinthe.Plug.GraphiQL,
  schema: MyAppWeb.Schema,
  socket: MyAppWeb.UserSocket
```

## Community

The project is under constant improvement by a growing list of
contributors, and your feedback is important. Please join us in Slack
(`#absinthe-graphql` under the Elixir Slack account) or the Elixir Forum
(tagged `absinthe`).

Please remember that all interactions in our official spaces follow
our [Code of Conduct](./CODE_OF_CONDUCT.md).

## Contributing

Please follow [contribution guide](./CONTRIBUTING.md).

## Copyright and License

Copyright (c) 2016 Bruce Williams, Ben Wilson

Released under the MIT License, which can be found in [LICENSE.md](./LICENSE.md).
