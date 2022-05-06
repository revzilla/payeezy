defmodule Payeezy.HTTP do
  @moduledoc """
  Base client for all server interaction, used by all endpoint specific
  modules. This request wrapper coordinates the remote server, headers,
  authorization and SSL options.

  This uses `HTTPoison.Base`, so all of the typical HTTP verbs are available.

  Using `Payeezy.HTTP` requires the presence of four config values:

  * apikey - Payeezy API key
  * apisecret - Payeezy API secret
  * token - Payeezy token
  * endpoint - Payeezy endpoint URL

  All four must have values set or a `Payeezy.ConfigError` will be raised
  at runtime.
  """
  require Logger
  use HTTPoison.Base

  @headers [
    {"Accept", "application/json"},
    {"User-Agent", "Payeezy Elixir/0.1"},
    {"Accept-Encoding", "gzip"},
    {"Content-type", "application/json"}
  ]

  def request(method, url, body, _headers \\ [], options \\ []) do
    super(method, url, body, header_authorization(body), options)
  end

  ## HTTPoison Callbacks

  @doc false
  def process_url(path) do
    endpoint = Payeezy.get_env(:endpoint)

    endpoint <> "/" <> path
  end

  @doc false
  def process_request_headers(headers) do
    headers ++ @headers
  end

  @doc false
  def process_request_body(body) when body == "" or body == %{},
    do: ""

  def process_request_body(body) do
    Poison.encode!(body)
  end

  @doc false
  def process_response_body(body) do
    Poison.Parser.parse!(body)
  rescue
    _ ->
      inspect(body)
  end

  defp header_authorization(body) do
    apikey = Payeezy.get_env(:apikey)
    token = Payeezy.get_env(:token)
    apisecret = Payeezy.get_env(:apisecret)
    epoch_timestamp = timestamp()
    nonce = generate_nonce()
    payload = Poison.encode!(body)

    string_timestamp = Integer.to_string(epoch_timestamp)
    data = apikey <> nonce <> string_timestamp <> token <> payload

    authorization = generate_hmac(apisecret, data)

    [
      {"apikey", apikey},
      {"token", token},
      {"apisecret", apisecret},
      {"Authorization", authorization},
      {"nonce", nonce},
      {"timestamp", epoch_timestamp}
    ]
  end

  defp generate_hmac(key, data) do
    Base.encode64(Base.encode16(:crypto.hmac(:sha256, key, "#{data}"), case: :lower))
  end

  defp generate_nonce do
    :rand.uniform() |> to_string |> String.replace("0.", "")
  end

  defp timestamp do
    :os.system_time(:milli_seconds)
  end
end
