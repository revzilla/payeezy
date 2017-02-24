defmodule Payeezy.GiftCard do
  @moduledoc """
  Payeezy gift card requests including
  balance_inquiry, purchase, and refund
  """
  @type t :: %__MODULE__{
    amount:              String.t,
    bank_message:        String.t,
    bank_resp_code:      String.t,
    correlation_id:      String.t,
    currency:            String.t,
    gateway_message:     String.t,
    gateway_resp_code:   String.t,
    method:              String.t,
    transaction_id:      String.t,
    transaction_status:  String.t,
    transaction_tag:     String.t,
    transaction_type:    String.t,
    validation_status:   String.t,
    valuelink:           map
  }

  defstruct amount:              nil,
            bank_message:        nil,
            bank_resp_code:      nil,
            correlation_id:      nil,
            currency:            nil,
            gateway_message:     nil,
            gateway_resp_code:   nil,
            method:              nil,
            transaction_id:      nil,
            transaction_status:  nil,
            transaction_tag:     nil,
            transaction_type:    nil,
            validation_status:   nil,
            valuelink:           %{}

  alias Payeezy.PostTransaction

  @doc """
  Complete a balance_inquiry for a given set of `params`
  """
  @spec balance_inquiry(map) :: {:ok, t} | {:error, any}
  def balance_inquiry(params) do
    post_params = "balance_inquiry" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete a purchase for a given set of `params`
  """
  @spec purchase(map) :: {:ok, t} | {:error, any}
  def purchase(params) do
    post_params = "purchase" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete a refund for a given set of `params`
  """
  @spec refund(map) :: {:ok, t} | {:error, any}
  def refund(params) do
    post_params = "refund" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete a deactivation for a given set of `params`
  """
  @spec deactivation(map) :: {:ok, t} | {:error, any}
  def deactivation(params) do
    post_params = "deactivation" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete an activation for a given set of `params`
  """
  @spec activation(map) :: {:ok, t} | {:error, any}
  def activation(params) do
    post_params = "activation" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete a reload for a given set of `params`
  """
  @spec reload(map) :: {:ok, t} | {:error, any}
  def reload(params) do
    post_params = "reload" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  @doc """
  Complete a void for a `transaction_id` and a given set of `params`
  """
  @spec void(String.t, map) :: {:ok, t} | {:error, any}
  def void(transaction_id, params) do
    post_params = "void" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params, "#{transaction_id}")
  end

  @doc """
  Complete a reload for a given set of `params`
  """
  @spec cashout(map) :: {:ok, t} | {:error, any}
  def cashout(params) do
    post_params = "cashout" |> defaults |> merge_params(params)
    PostTransaction.handle_response(__MODULE__, post_params)
  end

  defp defaults(endpoint) do
    %{
      transaction_type: endpoint,
      method: "valuelink"
    }
  end

  defp merge_params(current_map, %{valuelink: %{"cc_number" => cc_number}} = params) do
    merged_valuelink_params = Map.merge(params[:valuelink], %{"cc_number" => strip_gift_card(cc_number)})
    do_merge_valuelink_params(current_map, params, merged_valuelink_params)
  end
  defp merge_params(current_map, %{valuelink: %{cc_number: cc_number}} = params) do
    merged_valuelink_params = Map.merge(params[:valuelink], %{cc_number: strip_gift_card(cc_number)})
    do_merge_valuelink_params(current_map, params, merged_valuelink_params)
  end
  defp merge_params(current_map, params), do: do_merge_valuelink_params(current_map, params)

  defp do_merge_valuelink_params(current_map, params, merged_valuelink_params \\ %{}) do
    params
    |> Map.merge(%{valuelink: merged_valuelink_params})
    |> Map.merge(current_map)
  end

  defp strip_gift_card(nil), do: nil
  defp strip_gift_card(cc_string) do
    String.replace(cc_string, ~r/\D/, "")
  end

end
