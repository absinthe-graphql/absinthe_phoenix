# Changelog

## [2.0.4](https://github.com/absinthe-graphql/absinthe_phoenix/compare/v2.0.3...v2.0.4) (2025-12-03)

### Bug Fixes

* Add GC to transport process ([404bb20](https://github.com/absinthe-graphql/absinthe_phoenix/commit/404bb2025b407bb2bda5d355167ebd2cc6b637a3))
* Adds the option to periodically garbage collect the channel process ([1518b46](https://github.com/absinthe-graphql/absinthe_phoenix/commit/1518b46fa5658e163351f312c501d8e7cb6a9b2f))
* Fix assign key ([cdf3498](https://github.com/absinthe-graphql/absinthe_phoenix/commit/cdf34983e429eeb5c1d5372a33cf683323fba24b))
* support elixir 1.19 and otp 28 ([382e3fa](https://github.com/absinthe-graphql/absinthe_phoenix/commit/382e3fadbe208e46dc47d9ea455350219dc45f44))
* support elixir 1.19 and otp 28 ([c2bba06](https://github.com/absinthe-graphql/absinthe_phoenix/commit/c2bba061fb4d37008b337dcd0afd79807484c3d9))

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
