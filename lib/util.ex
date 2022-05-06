defmodule Payeezy.Util do
  @doc """
  Recursively convert a map of string keys into a map with atom keys. Intended
  to prepare responses for conversion into structs. Note that it only converts
  strings to known atoms.

  ## Example

      iex> Payeezy.Util.atomize(%{"a" => 1, "b" => %{"c" => 2}})
      %{a: 1, b: %{c: 2}}
  """
  @spec atomize(map()) :: map()
  def atomize(map) when is_map(map) do
    Enum.into(map, %{}, fn
      {key, val} when is_map(val) -> {String.to_atom(key), atomize(val)}
      {key, val} -> {String.to_atom(key), val}
    end)
  end
end
