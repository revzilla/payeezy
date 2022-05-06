defmodule Payeezy.PostTransaction do
  import Payeezy.Util, only: [atomize: 1]
  require Logger

  alias Payeezy.Client
  alias Payeezy.ErrorResponse, as: Error

  def handle_response(mod, params, url \\ "") do
    case Client.post(url, params) do
      {:ok, body_map} -> {:ok, construct(mod, body_map)}
      {:error, %{"Error" => error_map}} -> log_and_return_error(error_map)
      {:error, ":timeout"} -> {:error, %{"description" => "timeout"}}
      {:error, ":econnrefused"} -> {:error, %{"description" => "econnrefused"}}
    end
  end

  defp construct(mod, map) do
    struct(mod, atomize(map))
  end

  def log_and_return_error(error_map) do
    error = Error.construct(error_map)
    Logger.info("Payeezy Request Error : " <> error["description"])

    {:error, error}
  end
end
