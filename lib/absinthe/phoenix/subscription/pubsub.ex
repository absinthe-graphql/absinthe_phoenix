defmodule Absinthe.Phoenix.Subscription.Pubsub do
  @moduledoc false
  # Experimental module adding just enough functionality to help decouple from Phoenix.Endpoint

  defmacro __using__(opts) do
    quote do
      @behaviour Absinthe.Subscription.Pubsub
      @otp_app unquote(opts)[:otp_app] || raise("endpoint expects :otp_app to be given")
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def node_name() do
        Absinthe.Phoenix.Subscription.Pubsub.node_name(@otp_app, __MODULE__)
      end

      def publish_mutation(topic, mutation_result, subscribed_fields) do
        Absinthe.Phoenix.Subscription.Pubsub.publish_mutation(
          @otp_app,
          __MODULE__,
          topic,
          mutation_result,
          subscribed_fields
        )
      end

      def publish_subscription(topic, data) do
        Absinthe.Phoenix.Subscription.Pubsub.publish_subscription(
          @otp_app,
          __MODULE__,
          topic,
          data
        )
      end

      def subscribe(topic, opts \\ []) when is_binary(topic) do
        Absinthe.Phoenix.Subscription.Pubsub.subscribe(
          Absinthe.Phoenix.Subscription.Pubsub.pubsub(@otp_app, __MODULE__),
          topic,
          opts
        )
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

    Phoenix.PubSub.local_broadcast(pubsub, topic, broadcast, Phoenix.Channel.Server)
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

    Phoenix.PubSub.broadcast(pubsub, proxy_topic, message, Phoenix.Channel.Server)
  end

  @doc false
  def subscribe(pubsub_server, topic, opts \\ []) when is_binary(topic) do
    Phoenix.PubSub.subscribe(pubsub_server, topic, opts)
  end

  def pubsub(otp_app, endpoint) do
    pubsub =
      Application.get_env(otp_app, endpoint)[:pubsub][:name] ||
        Application.get_env(otp_app, endpoint)[:pubsub_server]

    pubsub ||
      raise """
      Pubsub needs to be configured for #{inspect(otp_app)} #{inspect(endpoint)}!
      """
  end
end
