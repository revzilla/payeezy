defmodule Payeezy.TestHelpers do
  @doc "Creates a Bypass listener to act as a double for the actual Payeezy GiftCard API endpoint"
  @spec build_bypass :: any
  def build_bypass do
    bypass = Bypass.open
    Application.put_env(:payeezy, :endpoint, "http://localhost:#{bypass.port}")
    bypass
  end

  @doc "Simulates that the provided Bypass listener is not accepting connections"
  @spec simulate_service_down(any) :: nil
  def simulate_service_down(bypass) do
    Bypass.down(bypass)
    nil
  end

  @spec simulate_service_response(any, Plug.Conn.status, String.t, (Plug.Conn.t -> boolean)) :: no_return
  def simulate_service_response(bypass, status, body, fun) when is_function(fun) do
    Bypass.expect(bypass, fn(conn) ->
      if fun.(conn |> Plug.Conn.fetch_query_params) do
        Plug.Conn.resp(conn, status, body)
      end
    end)
  end

  @spec simulate_balance_inquiry_and_purchase_success(any, String.t) :: no_return
  def simulate_balance_inquiry_and_purchase_success(bypass, balance) do
    Bypass.expect(bypass, fn(conn) ->
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      case Poison.decode!(body)["transaction_type"] do
        "balance_inquiry" -> Plug.Conn.resp(conn, :ok, successful_balance_inquiry_response_string(balance))
        "purchase" -> Plug.Conn.resp(conn, :ok, successful_purchase_response_string(
                      Poison.decode!(body)["amount"], "2.00", balance))
      end
    end)
  end

  @spec simulate_balance_inquiry_and_purchase_insufficient_funds(any, String.t) :: no_return
  def simulate_balance_inquiry_and_purchase_insufficient_funds(bypass, balance) do
    Bypass.expect(bypass, fn(conn) ->
      {:ok, body, conn} = Plug.Conn.read_body(conn, length: 1_000_000)
      case Poison.decode!(body)["transaction_type"] do
        "balance_inquiry" -> Plug.Conn.resp(conn, :ok, successful_balance_inquiry_response_string(balance))
        "purchase" -> Plug.Conn.resp(conn, :ok, purchase_failure_insufficient_funds(Poison.decode!(body)["amount"]))
      end
    end)
  end

  @spec successful_balance_inquiry_response_string(String.t) :: String.t
  def successful_balance_inquiry_response_string(current_balance) do
    ~s(
      {"transaction_status":"approved","transaction_type":"balance_inquiry",
      "transaction_id":"ET158511","transaction_tag":"85217552","method":"valuelink",
      "amount":"0", "valuelink":{"cardholder_name":"Joe Smith","cc_number":"############0450",
      "credit_card_type":"Gift","previous_balance":"#{current_balance}","current_balance":"#{current_balance}"}}
    )
  end

  @spec successful_purchase_response_string(String.t, String.t, String.t) :: String.t
  def successful_purchase_response_string(purchase_amount, current_balance, previous_balance) do
    ~s(
      {"correlation_id":"124.1465492224818","transaction_status":"approved","validation_status":"success",
      "transaction_type":"purchase","transaction_id":"ET155291","transaction_tag":"85279916",
      "method":"valuelink","amount":"#{purchase_amount}","currency":"USD","bank_resp_code":"100",
      "bank_message":"Approved","gateway_resp_code":"00","gateway_message":"Transaction Normal",
      "valuelink":{"cardholder_name":"Joe Smith","cc_number":"############0450",
      "credit_card_type":"Gift","previous_balance":"#{previous_balance}","current_balance":"#{current_balance}"},
      "post_date":"04032016","value_link_auth_code":"100","local_currency_code":"840"}
    )
  end

  def purchase_failure_insufficient_funds(purchase_amount) do
    ~s(
    {"correlation_id":"124.1465493001356","transaction_status":"declined","validation_status":"success",
    "transaction_type":"purchase","transaction_tag":"85281386","method":"valuelink",
    "amount":"#{purchase_amount}","currency":"USD","bank_resp_code":"253","bank_message":"Insufficient Funds",
    "gateway_resp_code":"00","gateway_message":"Transaction Normal","valuelink":{"cardholder_name":"Joe Smith",
    "cc_number":"############5463","credit_card_type":"Gift","previous_balance":"0.0","current_balance":"0.0"},
    "value_link_auth_code":"null"}
    )
  end

  @spec purchase_failure_missing_cc_response_string() :: String.t
  def purchase_failure_missing_cc_response_string do
    ~s(
        {"Error":{
          "messages":[{"code":"400","description":"Bad Request \x2822\x29 - Invalid Credit Card Number"}]},
          "transaction_status":"Not Processed"
        }
      )
  end

  @spec successful_refund_response_string(String.t) :: String.t
  def successful_refund_response_string(refund_amount) do
    ~s(
      {"correlation_id":"124.1465493219707","transaction_status":"approved","validation_status":"success",
      "transaction_type":"refund","transaction_id":"ET108911","transaction_tag":"85281467","method":"valuelink",
      "amount":"#{refund_amount}","currency":"USD","bank_resp_code":"100","bank_message":"Approved",
      "gateway_resp_code":"00","gateway_message":"Transaction Normal",
      "valuelink":{"cardholder_name":"Joe Smith","cc_number":"############0450","credit_card_type":"Gift",
      "previous_balance":"79.9","current_balance":"82.9"},"value_link_auth_code":"null"}
    )
  end

  def successful_void_response_string(void_amount) do
    ~s(
    {"correlation_id":"124.1484081214861","transaction_status":"approved","validation_status":"success",
    "transaction_type":"void","transaction_id":"ET193321","transaction_tag":"132851240","method":"valuelink",
    "amount":"#{void_amount}","currency":"USD","bank_resp_code":"100","bank_message":"Approved",
    "gateway_resp_code":"00","gateway_message":"TransactionNormal","valuelink":{"cardholder_name":"JoeSmith",
    "cc_number":"############5463","credit_card_type":"Gift","previous_balance":"2.0","current_balance":"6.0"},
    "value_link_auth_code":"null"}
    )
  end
end
