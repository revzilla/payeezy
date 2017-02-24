defmodule Payeezy.ErrorResponse do
  @moduledoc """
  A general purpose response wrapper that is built for any failed API
  response.
  """

  import Payeezy.Util, only: [atomize: 1]

  @type t :: %__MODULE__{
   messages: Keyword.t
  }

  defstruct messages: %{}

  @spec construct(map) :: t
  def construct(map) do
    [message_map | _tail] = struct(__MODULE__, atomize(map)).messages
    message_map
  end
end
