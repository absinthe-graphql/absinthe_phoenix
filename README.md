# Absinthe.Phoenix

[![Hex pm](http://img.shields.io/hexpm/v/absinthe_phoenix.svg?style=flat)](https://hex.pm/packages/absinthe_phoenix)[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

This package integrates Absinthe subscriptions with Phoenix, so that you can use subscriptions via websockets.

For getting started guides on subscriptions see: https://hexdocs.pm/absinthe/subscriptions.html

For getting started guides on server side rendering see: https://hexdocs.pm/absinthe/subscriptions.html

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe_phoenix):

```elixir
def deps do
  [{:absinthe_phoenix, "~> 1.4.0"}]
end
```

You need to have a working phoenix pubsub configured. Here is what the default looks like if you create a new phoenix project:

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ... other config
  pubsub: [name: MyApp.PubSub,
           adapter: Phoenix.PubSub.PG2]
```

In your application supervisor add a line AFTER your existing endpoint supervision
line:

```elixir
[
  # other children ...
  supervisor(MyAppWeb.Endpoint, []), # this line should already exist
  supervisor(Absinthe.Subscription, [MyAppWeb.Endpoint]), # add this line
  # other children ...
]
```

Where `MyAppWeb.Endpoint` is the name of your application's phoenix endpoint.

In your `MyAppWeb.Endpoint` module add:
```elixir
use Absinthe.Phoenix.Endpoint
```

In your socket add:

#### Phoenix 1.3
```elixir
use Absinthe.Phoenix.Socket,
  schema: MyAppWeb.Schema
```

#### Phoenix 1.2

```elixir
  use Absinthe.Phoenix.Socket
  def connect(_params, socket) do
    socket = Absinthe.Phoenix.Socket.put_schema(socket, MyAppWeb.Schema)
    {:ok, socket}
  end
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
