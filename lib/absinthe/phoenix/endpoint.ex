defmodule Absinthe.Phoenix.Endpoint do
  defmacro __using__(_) do
    quote do
      @behaviour Absinthe.Subscription.Pubsub
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def node_name() do
        Absinthe.Phoenix.Endpoint.node_name(@otp_app, __MODULE__)
      end

      def publish_mutation(topic, mutation_result, subscribed_fields) do
        Absinthe.Phoenix.Endpoint.publish_mutation(
          @otp_app,
          __MODULE__,
          topic,
          mutation_result,
          subscribed_fields
        )
      end

      def publish_subscription(topic, data) do
        Absinthe.Phoenix.Endpoint.publish_subscription(@otp_app, __MODULE__, topic, data)
      end
    end
  end

  @doc false
  def node_name(otp_app, endpoint) do
    pubsub = pubsub(otp_app, endpoint)

    Phoenix.PubSub.node_name(pubsub)
  end

  @doc false
  # when publishing subscription results we only care about
  # publishing to the local node. Each node manages and runs documents separately
  # so there's no point in pushing out the results to other nodes.
  def publish_subscription(otp_app, endpoint, topic, result) do
    pubsub = pubsub(otp_app, endpoint)

    broadcast = %Phoenix.Socket.Broadcast{
      topic: topic,
      event: "subscription:data",
      payload: %{result: result, subscriptionId: topic}
    }

    pubsub
    |> Phoenix.PubSub.node_name()
    |> Phoenix.PubSub.direct_broadcast(pubsub, topic, broadcast)
  end

  @doc false
  def publish_mutation(otp_app, endpoint, proxy_topic, mutation_result, subscribed_fields) do
    pubsub = pubsub(otp_app, endpoint)

    # we need to include the current node as part of the broadcast.
    # This is because this broadcast will also be picked up by proxies within the
    # current node, and they need to be able to ignore this message.
    message = %{
      node: node_name(otp_app, endpoint),
      subscribed_fields: subscribed_fields,
      mutation_result: mutation_result
    }

    Phoenix.PubSub.broadcast(pubsub, proxy_topic, message)
  end

  defp pubsub(otp_app, endpoint) do
    Application.get_env(otp_app, endpoint)[:pubsub][:name] ||
      raise """
      Pubsub needs to be configured for #{inspect(otp_app)} #{inspect(endpoint)}!
      """
  end
end
