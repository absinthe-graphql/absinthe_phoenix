defmodule Schema.Types do
  use Absinthe.Schema.Notation

  object :mutation_fields do
    field :add_comment, :comment do
      arg :contents, non_null(:string)

      resolve fn %{contents: contents}, _ ->
        comment = %{contents: contents}
        {:ok, comment}
      end
    end
  end
end

defmodule Schema do
  use Absinthe.Schema

  import_types Schema.Types

  object :comment do
    field :contents, :string
  end

  object :user do
    field :name, :string
    field :age, :integer
  end

  object :slow_field do
    field :value, :integer do
      resolve fn %{value: value}, _, _ ->
        Process.sleep(value)
        {:ok, value}
      end
    end
  end

  query do
    field :me, :user do
      resolve fn _, %{context: context} ->
        {:ok, context[:current_user]}
      end
    end

    field :users, list_of(:user) do
      resolve fn _, _ ->
        users = [
          %{name: "Bob", age: 29}
        ]

        {:ok, users}
      end
    end
    field :slow_field, :slow_field do
      arg :delay, non_null(:integer)
      resolve fn _, args, _ ->
        {:ok, %{value: args.delay}}
      end
    end
  end

  mutation do
    import_fields :mutation_fields

    field :login, :user do
      middleware fn res, _ ->
        user = %{name: "Ben"}

        res
        |> Map.update!(:context, &Map.put(&1, :current_user, user))
        |> Absinthe.Resolution.put_result({:ok, user})
      end
    end

    field :mutate, :integer do
      arg :val, :integer

      resolve fn _, %{val: val}, _ ->
        {:ok, val}
      end
    end
  end

  subscription do
    field :comment_added, :comment do
      config fn _args, _info ->
        {:ok, topic: ""}
      end

      trigger :add_comment,
        topic: fn _comment ->
          ""
        end
    end

    field :raises, :comment do
      config fn _, _ ->
        {:ok, topic: "raise"}
      end

      trigger :add_comment,
        topic: fn comment ->
          comment.contents
        end

      resolve fn _, _ -> raise "boom" end
    end

    field :errors, :comment do
      config fn _, _ ->
        {:error, "unauthorized"}
      end
    end
  end
end
