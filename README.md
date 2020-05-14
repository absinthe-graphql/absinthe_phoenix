# Absinthe.Phoenix

[![Hex pm](http://img.shields.io/hexpm/v/absinthe_phoenix.svg?style=flat)](https://hex.pm/packages/absinthe_phoenix)[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/absinthe-graphql/absinthe_phoenix.svg?branch=master)](https://travis-ci.org/absinthe-graphql/absinthe_phoenix)

This package integrates Absinthe subscriptions with Phoenix, so that you can use subscriptions via websockets.

For getting started guides on subscriptions see: https://hexdocs.pm/absinthe/subscriptions.html

For getting started guides on server side rendering see: https://hexdocs.pm/absinthe/subscriptions.html

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe_phoenix):

For Phoenix 1.4, see the v1.5 branch: https://github.com/absinthe-graphql/absinthe_phoenix/tree/v1.5

### Phoenix 1.5

```elixir
def deps do
  [{:absinthe_phoenix, "~> 2.0.0"}]
end
```

You need to have a working phoenix pubsub configured. Here is what the default looks like if you create a new phoenix project:

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
  {Absinthe.Subscription, [MyAppWeb.Endpoint]}, # add this line
  # other children ...
]
```

Where `MyAppWeb.Endpoint` is the name of your application's phoenix endpoint.

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

## License

See [LICENSE.md](./LICENSE.md).
