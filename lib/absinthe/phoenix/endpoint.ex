defmodule Absinthe.Phoenix.Endpoint do
  defmacro __using__(_) do
    quote do
      @behaviour Absinthe.Subscription.Pubsub

      def publish_mutation(topic, data) do
        Absinthe.Phoenix.Endpoint.publish_mutation(@otp_app, __MODULE__, topic, data)
      end
      def publish_subscription(topic, data) do
        Absinthe.Phoenix.Endpoint.publish_subscription(@otp_app, __MODULE__, topic, data)
      end
    end
  end

  @doc false
  def publish_mutation(_otp_app, endpoint, topic, payload) do
    endpoint.broadcast!(topic, "mutation", payload)
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
      payload: %{result: result, subscriptionId: topic},
    }

    pubsub
    |> Phoenix.PubSub.node_name()
    |> Phoenix.PubSub.direct_broadcast(pubsub, topic, broadcast)
  end

  defp pubsub(otp_app, endpoint) do
    Application.get_env(otp_app, endpoint)[:pubsub][:name] || raise """
    Pubsub needs to be configured for #{inspect otp_app} #{inspect endpoint}!
    """
  end
end
