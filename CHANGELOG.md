# Changelog

## v2.0.3 - 2024-04-02

- Add official support for Elixir 1.15 and OTP 26
- Drop support for Elixir 1.10
- Add support for `phoenix_html` 4.0
- Add `:gc_interval` option to periodically run `:erlang.garbage_collect`, which can help with memory bloat (see [PR](https://github.com/absinthe-graphql/absinthe_phoenix/pull/100))

## v2.0.2 - 2021-09-01

- Add support for `phoenix_html` 3.0

## v2.0.1 - 2021-02-09

- Add support for `decimal` 2.0
- Relax version requirement for Absinthe

## v2.0.0 - 2020-05-14

- Phoenix.PubSub 2.0 support

## v1.5.0 - 2020-05-14

- Absinthe 1.5 support

## v1.4.4 - 2019-05-04

- Remove unintentional poison dependency

## v1.4.2 - 2018-01-22

- Add `variables/1` function to make it easy to get the original parameters

## v1.4.1 - 2018-01-21

- Deprecate `Absinthe.Phoenix.Socket.put_opts/2` in favor of `Absinthe.Phoenix.Socket.put_options/2` for consistency with Absinthe.Plug

## v1.4.0 - 2017-11-13

- First real release.
