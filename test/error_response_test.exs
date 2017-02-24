defmodule Payeezy.ErrorResponseTest do
  use ExUnit.Case, async: true

  alias Payeezy.ErrorResponse

  test "converting an api error response" do
    response = %{
      "messages" => [
        %{
          "code" => "400",
          "description" => "Bad Request (22) - Invalid Credit Card Number"
        }
      ]
    }

    error_response = ErrorResponse.construct(response)

    assert error_response["code"] == "400"
    assert error_response["description"] == "Bad Request (22) - Invalid Credit Card Number"
  end
end
