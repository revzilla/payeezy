defmodule Payeezy.Integration.GiftCardTest do
  use ExUnit.Case
  import Payeezy.TestHelpers

  alias Payeezy.GiftCard

  setup context do
    {:ok,
      apikey: Application.put_env(:payeezy, :apikey, "fake"),
      token: Application.put_env(:payeezy, :token, "fake"),
      apisecret: Application.put_env(:payeezy, :apisecret, "fake"),
      payeezy_bypass: (if context[:skip_payeezy_bypass], do: nil, else: build_bypass)
    }
  end

  @tag :skip_payeezy_bypass
  test """
  balance_inquiry/1
  when the endpoint configuration is not set
  raises an error
  """ do
    Application.put_env(:payeezy, :endpoint, nil)

    assert_raise Payeezy.ConfigError, "missing config for :endpoint", fn ->
      GiftCard.balance_inquiry(%{})
    end
  end

  test """
  balance_inquiry/1
  when the apikey configuration is not set
  raises an error
  """ do
    Application.put_env(:payeezy, :apikey, nil)

    assert_raise Payeezy.ConfigError, "missing config for :apikey", fn ->
      GiftCard.balance_inquiry(%{})
    end
  end

  test """
  balance_inquiry/1
  when the service endpoint is down
  returns an error
  """, %{payeezy_bypass: payeezy_bypass} do
    payeezy_bypass
    |> simulate_service_down

    result = GiftCard.balance_inquiry(%{})

    assert result == {:error, %{"description" => "econnrefused"}}
  end

  test "balance_inquiry/1 can check balance of gift card", %{payeezy_bypass: payeezy_bypass} do
    response = successful_balance_inquiry_response_string("170.05")
    params = %{
      valuelink: %{
        cardholder_name: "Joe Smith",
        cc_number: "7777045236850450",
        credit_card_type: "Gift"
      }
    }

    payeezy_bypass
    |> simulate_service_response(:ok, response, fn(conn) -> conn.method == "POST" end)

    {:ok, inquiry_struct} = GiftCard.balance_inquiry(params)

    assert inquiry_struct.valuelink.current_balance == "170.05"
    assert inquiry_struct.transaction_status == "approved"
    assert inquiry_struct.transaction_type == "balance_inquiry"
  end

  test "balance_inquiry/1 will strip non numeric characters from cc_number", %{payeezy_bypass: payeezy_bypass} do
    response = successful_balance_inquiry_response_string("170.05")
    params = %{
      valuelink: %{
        cardholder_name: "Joe Smith",
        cc_number: "7777-0452-3685-0450",
        credit_card_type: "Gift"
      }
    }

    payeezy_bypass
    |> simulate_service_response(:ok, response, fn(conn) -> conn.method == "POST" end)

    {:ok, inquiry_struct} = GiftCard.balance_inquiry(params)

    assert inquiry_struct.valuelink.current_balance == "170.05"
    assert inquiry_struct.transaction_status == "approved"
    assert inquiry_struct.transaction_type == "balance_inquiry"
  end

  test "balance_inquiry/1 fails when missing cardholder_name", %{payeezy_bypass: payeezy_bypass} do
    response = ~s(
      {"Error":{
        "messages":[{"code":"400","description":"Bad Request \x2827\x29 - Invalid Card Holder"}]},
        "transaction_status":"Not Processed"
      }
    )

    params = %{valuelink: %{cc_number: "7777045236850450", credit_card_type: "Gift"}}

    payeezy_bypass
    |> simulate_service_response(:bad_request, response, fn(conn) -> conn.method == "POST" end)

    {:error, error} = GiftCard.balance_inquiry(params)

    assert error["description"] == "Bad Request (27) - Invalid Card Holder"
  end

  test "balance_inquiry/1 fails when missing cc number", %{payeezy_bypass: payeezy_bypass} do
    response = purchase_failure_missing_cc_response_string
    params = %{valuelink: %{cardholder_name: "Joe Smith", credit_card_type: "Gift"}}

    payeezy_bypass
    |> simulate_service_response(:bad_request, response, fn(conn) -> conn.method == "POST" end)

    {:error, error} = GiftCard.balance_inquiry(params)

    assert error["description"] == "Bad Request (22) - Invalid Credit Card Number"
  end

  test "purchase/1 can check balance of gift card", %{payeezy_bypass: payeezy_bypass} do
    response = successful_purchase_response_string("400", "79.9", "83.9")
    params = %{
      amount: "400",
      currency_code: "USD",
      valuelink: %{cardholder_name: "Joe Smith", cc_number: "7777045839985463", credit_card_type: "Gift"}
    }

    payeezy_bypass
    |> simulate_service_response(:ok, response, fn(conn) -> conn.method == "POST" end)

    {:ok, purchase_struct} = GiftCard.purchase(params)
    assert purchase_struct.amount == "400"
    assert purchase_struct.valuelink.current_balance == "79.9"
    assert purchase_struct.valuelink.previous_balance == "83.9"
    assert purchase_struct.transaction_status == "approved"
  end

  test "purchase/1 fails when cc number is not specified", %{payeezy_bypass: payeezy_bypass} do
    response = purchase_failure_missing_cc_response_string
    params = %{
      amount: "400",
      post_date: "04032016",
      valuelink: %{cardholder_name: "Joe Smith",credit_card_type: "Gift"}
    }

    payeezy_bypass
    |> simulate_service_response(:bad_request, response, fn(conn) -> conn.method == "POST" end)

    {:error, error} = GiftCard.purchase(params)
    assert error["description"] == "Bad Request (22) - Invalid Credit Card Number"
  end

  test "refund/1 can refund gift card", %{payeezy_bypass: payeezy_bypass}  do
    response = successful_refund_response_string("2100")
    params = %{
      amount: "2100",
      currency_code: "USD",
      post_date: "04032016",
      valuelink: %{cardholder_name: "Joe Smith",cc_number: "7777045236850450",credit_card_type: "Gift"
      }
    }

    payeezy_bypass
    |> simulate_service_response(:ok, response, fn(conn) -> conn.method == "POST" end)

    {:ok, refund_struct} = GiftCard.refund(params)
    assert refund_struct.amount == "2100"
    assert refund_struct.transaction_status == "approved"
    assert refund_struct.transaction_type == "refund"
    assert refund_struct.valuelink.current_balance == "82.9"
  end

  test "refund/1 fails without an amount specified", %{payeezy_bypass: payeezy_bypass}  do
    response = ~s(
    {"Error":{"messages":[{"code":"missing_amount","description":"The amount is missing"}]},
    "transaction_status":"Not Processed","validation_status":"failed",
    "transaction_type":"purchase","method":"valuelink","currency":"USD"}
    )

    params = %{
      currency_code: "USD",
      post_date: "04032016",
      valuelink: %{cardholder_name: "Joe Smith", cc_number: "7777045839985463",credit_card_type: "Gift"}
    }

    payeezy_bypass
    |> simulate_service_response(:bad_request, response, fn(conn) -> conn.method == "POST" end)

    {:error, error} = GiftCard.refund(params)
    assert error["description"] == "The amount is missing"
  end

  test "void/2 can void a transaction", %{payeezy_bypass: payeezy_bypass} do
    response = successful_void_response_string("400")

    params = %{
      amount: "400",
      currency_code: "USD",
      post_date: "04032016",
      valuelink: %{cardholder_name: "Joe Smith",cc_number: "7777045236850450",credit_card_type: "Gift"}
    }

    payeezy_bypass
    |> simulate_service_response(:ok, response, fn(conn) -> conn.method == "POST" end)

    {:ok, refund_struct} = GiftCard.void("ET193321", params)
    assert refund_struct.amount == "400"
    assert refund_struct.transaction_status == "approved"
    assert refund_struct.transaction_type == "void"
    assert refund_struct.valuelink.previous_balance == "2.0"
    assert refund_struct.valuelink.current_balance == "6.0"
  end

  test "void/2 fails without an amount specified", %{payeezy_bypass: payeezy_bypass} do
    response = ~s(
    {"Error":{"messages":[{"code":"missing_amount","description":"The amount is missing"}]},
    "transaction_status":"Not Processed","validation_status":"failed",
    "transaction_type":"purchase","method":"valuelink","currency":"USD"}
    )

    params = %{
      currency_code: "USD",
      post_date: "04032016",
      valuelink: %{cardholder_name: "Joe Smith", cc_number: "7777045839985463",credit_card_type: "Gift"}
    }

    payeezy_bypass
    |> simulate_service_response(:bad_request, response, fn(conn) -> conn.method == "POST" end)

    {:error, error} = GiftCard.void("ET193321", params)
    assert error["description"] == "The amount is missing"
  end

  @tag :skip
  test "deactivation/1 success" do

  end

  @tag :skip
  test "deactivation/1 failure" do

  end

  @tag :skip
  test "activation/1 success" do

  end

  @tag :skip
  test "activation/1 failure" do

  end

  @tag :skip
  test "reload/1 success" do

  end

  @tag :skip
  test "reload/1 failure" do

  end

  @tag :skip
  test "cashout/1 success" do

  end

  @tag :skip
  test "cashout/1 failure" do

  end
end
