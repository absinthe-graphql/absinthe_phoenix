# Absinthe.Phoenix

## Subscriptions

This readme is going to be the primary source of info on how to use Absinthe Subscriptions
while they're in beta.

Libraries you'll need:

```elixir
{:absinthe, github: "absinthe-graphql/absinthe", branch: "subscriptions"},
{:absinthe_phoenix, github: "absinthe-graphql/absinthe_phoenix", branch: "subscriptions"},
```

In your application supervisor add:

```elixir
supervisor(Absinthe.Subscription, [MyApp.Web.Endpoint]),
```

Where `MyApp.Web.Endpoint` is the name of your application's phoenix endpoint.

In your `MyApp.Web.Endpoint` module add:
```elixir
use Absinthe.Phoenix.Endpoint
```

In your socket add:

```elixir
use Absinthe.Phoenix.Channel
```

You also need to configure the schema by adding it to the socket assigns. Here
is an example socket:

```elixir
defmodule GitHunt.Web.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Channel

  transport :websocket, Phoenix.Transports.WebSocket

  def connect(_params, socket) do
    socket = socket |> assign(:absinthe, %{
      schema: MyApp.Web.Schema,
    })

    {:ok, socket}
  end

  def id(_socket), do: nil
end
```

Where `MyApp.Web.Schema` is the name of your Absinthe schema module.

That is all that's required for setup on the server.

### Javascript

Minimal javascript (ES6)

COMING SOON

### Schema

```elixir
mutation do
  field :submit_comment, :comment do
    arg :repo_full_name, non_null(:string)
    arg :comment_content, non_null(:string)

    resolve &Github.submit_comment/3
  end
end

subscription do
  field :comment_added, :comment do
    arg :repo_full_name, non_null(:string)

    # this tells Absinthe to run any subscriptions with this field every time
    # the :submit_comment mutation happens.
    # It also has a topic function used to find what subscriptions care about
    # this particular comment
    trigger :submit_comment, topic: fn comment ->
      comment.repository_name
    end

    # The topic function is used to determine what topic a given subscription
    # cares about based on its arguments.
    topic fn args ->
      args.repo_full_name
    end

    resolve fn %{comment_added: comment}, _, _ ->
      # this function is often not actually necessary, as the default resolver
      # will pull the root value off properly.
      # It's only here to show what happens.
      {:ok, comment}
    end

  end
end
```
