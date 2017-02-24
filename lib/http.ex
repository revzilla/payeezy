defmodule Payeezy.HTTP do
  @moduledoc """
  Base client for all server interaction, used by all endpoint specific
  modules. This request wrapper coordinates the remote server, headers,
  authorization and SSL options.

  This uses `HTTPoison.Base`, so all of the typical HTTP verbs are avialble.

  Using `Payeezy.HTTP` requires the presence of three config values:

  * apikey - Payeezy API key
  * apisecret - Payeezy API secret
  * token - Payeezy token

  All three must have values set or a `Payeezy.ConfigError` will be raised
  at runtime.
  """
  require Logger
  use HTTPoison.Base
  alias HTTPoison.Response
  alias HTTPoison.AsyncResponse

  @headers [
    {"Accept", "application/json"},
    {"User-Agent", "Payeezy Elixir/0.1"},
    {"Accept-Encoding", "gzip"},
    {"Content-type", "application/json"}
  ]

  @spec request(atom, binary, binary, headers, Keyword.t) ::
        {:ok, Response.t | AsyncResponse.t} | {:error, integer, Response.t} | {:error, any}
  def request(method, url, body, _headers \\ [], options \\ []) do
    response = super(method, url, body, header_authorization(body), options)
    process_response(response)
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
    body |> Poison.Parser.parse!
  end

  @doc false
  def process_response({:ok, %{status_code: code, body: body}})
      when code >= 200 and code <= 399,
    do: {:ok, body}
  def process_response({:ok, %{status_code: 401}}),
    do: {:error, :unauthorized}
  def process_response({:ok, %{status_code: 404}}),
    do: {:error, :not_found}
  def process_response({:ok, %{body: body}}),
    do: {:error, body}
  def process_response({:error, ":econnrefused"}),
    do: {:error, :econnrefused}
  def process_response({_code, %HTTPoison.Error{reason: reason}}),
    do: {:error, inspect(reason)}

  defp header_authorization(body) do
    apikey = Payeezy.get_env(:apikey)
    token = Payeezy.get_env(:token)
    apisecret = Payeezy.get_env(:apisecret)
    epoch_timestamp = timestamp()
    nonce = generate_nonce()
    payload = Poison.encode!(body)

    string_nonce = nonce |> Integer.to_string
    string_timestamp = epoch_timestamp |> Integer.to_string
    data = apikey <> string_nonce <> string_timestamp <> token <> payload

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
    :rand.uniform |> to_string |> String.replace("0.", "") |> String.to_integer
  end

  defp timestamp do
    :milli_seconds |> :os.system_time
  end
end
