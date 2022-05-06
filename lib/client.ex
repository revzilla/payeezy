defmodule Payeezy.Client do
  @moduledoc """
  Client module for Payeezy API.
  """

  @doc """
  Performs POST request and returns parsed response.
  """
  @spec post(String.t(), any()) ::
          {:ok, map()} | {:error, :unauthorized | :not_found | map() | String.t()}
  def post(url, params) do
    url
    |> Payeezy.HTTP.post(params)
    |> parse_response()
  end

  @spec parse_response({atom(), String.t() | map()}) :: {:ok, any()} | {:error, any()}
  defp parse_response({:ok, %{status_code: code, body: body}})
       when code >= 200 and code <= 399,
       do: {:ok, body}

  defp parse_response({:ok, %{status_code: 401}}),
    do: {:error, :unauthorized}

  defp parse_response({:ok, %{status_code: 404}}),
    do: {:error, :not_found}

  defp parse_response({:ok, %{body: body}}),
    do: {:error, body}

  defp parse_response({_code, %HTTPoison.Error{reason: reason}}),
    do: {:error, inspect(reason)}
end
