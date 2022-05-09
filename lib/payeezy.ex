defmodule Payeezy do
  @moduledoc """
  Payeezy client library for Elixir. Right now this only supports
  GiftCardAdditional and GiftCardPurchase endpoints. More support will
  come as needed.

  For api reference, please visit:
  https://developer.payeezy.com/payeezy-api/apis/
  """

  defmodule ConfigError do
    @moduledoc """
    Raised at runtime when a config variable is missing.
    """

    defexception [:message]

    def exception(value) do
      message = "missing config for :#{value}"

      %ConfigError{message: message}
    end
  end

  @doc """
  Convenience function for retrieving payeezy specfic environment values, but
  will raise an exception if values are missing.
  ## Example
      iex> Payeezy.get_env(:random_value)
      ** (Payeezy.ConfigError) missing config for :random_value
  """
  @spec get_env(atom()) :: any()
  def get_env(key) do
    Application.get_env(:payeezy, key) || raise ConfigError, key
  end
end
