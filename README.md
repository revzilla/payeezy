[![Build Status](https://travis-ci.org/revzilla/payeezy.svg?branch=master)](https://travis-ci.org/revzilla/payeezy)

[![Coverage Status](https://coveralls.io/repos/github/revzilla/payeezy/badge.svg?branch=master)](https://coveralls.io/github/revzilla/payeezy?branch=master)

# Payeezy

An elixir library for Payeezy payment. Currently supports ValueLink gift card transactions only.

See API documentation [here](https://developer.payeezy.com/payeezy-api/apis/)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add payeezy to your list of dependencies in `mix.exs`:

        ```elixir
        def deps do
          [{:payeezy, "~> 0.1.4"}]
        end
        ```

  2. Ensure payeezy is started before your application:

        ```elixir
        def application do
          [applications: [:payeezy]]
        end
        ```

## Setup
To setup, place credentials in your {env}.ex or {env}.secret.ex config files as shown below:
```elixir
config :payeezy,
  apikey: [ACCOUNT_API_KEY],
  token: [MERCHANT_TOKEN],
  apisecret: [ACCOUNT_API_SECRET]
```
