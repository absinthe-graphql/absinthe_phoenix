# Absinthe.Phoenix

This is still in the very early phases, expect changes.

Absinthe's GraphQL implementation gives you the ability to richly describe the
shape of data your server accepts. In this library we apply some of those capabilities
to easily validate and transform your phoenix controller params.

See http://absinthe-graphql.org/ for general GraphQL guides.

## Basic Usage

Suppose we want to offer a number of filters on a list of blog posts. We want to
require that they set an `after` param, we want a `before` param that defaults
to the current time, and we want to optionally let them filter by author. Author
can be looked up by either email or id. They can also filter by tag.

Example ordinary phoenix parameters that meet this criterion might look like
```elixir
%{
  "after" => "2015-12-12T11:11:11Z",
  "author" => %{"email" => "foo@bar.com"},
  "tags" => ["absinthe", "elixir"],
}
```

```elixir
use Absinthe.Phoenix

# By defining a time type, Absinthe will automatically parse the incoming
# string and turn it into an actual Calendar struct, so it can be immediately
# used with queries.
scalar :time do
  parse &Calendar.DateTime.Parse.rfc3339_utc/1
  serialize &Calendar.DateTime.Format.rfc3339/1
end

input_object :author_input do
  field :id, :id
  field :email, :string
end

input_object :index do
  field :after, non_null(:time)
  field :before, :time, default_value: Calendar.DateTime.now_utc()
  field :author, :author_input
  field :tags, list_of(:string)
end

def index(conn, params) do
  # do stuff
end
```

What this will give us as params are

```elixir
%{
  before: %Calendar.DateTime{...},
  after: %Calendar.DateTime{...},
  author: %{email: "foo@bar.com"},
  tags: ["absinthe", "elixir"]
}
```

Note how the params include the default value for `after` we specified, and that
the times have been converted to actual calendar structs.By defining what data
we accepted ahead of time, we can safely use atom keys.

We are also guaranteed that all parameters specified as `non_null` will be present.
If they are not, an error will be sent back to the user.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `absinthe_phoenix` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:absinthe_phoenix, "~> 0.0.1"}]
    end
    ```

  2. Ensure `absinthe_phoenix` is started before your application:

    ```elixir
    def application do
      [applications: [:absinthe_phoenix]]
    end
    ```
