defmodule ExTicketUtils.ClientTest do
  use ExUnit.Case

  alias ExTicketUtils.Client

  setup do
    server = Bypass.open
    url = "http://localhost:#{server.port}"

    Application.put_env(:ex_ticket_utils, :base_url, url)

    creds = %{
      customer_id: "12345",
      developer_auth_token_id: "67890",
      developer_auth_token: "54321",
      customer_auth_token: "09876",
    }

    {:ok, server: server, url: url, creds: creds}
  end

  test "can create a client", %{creds: creds} do
    {:ok, client} = Client.create(creds)

    assert client.customer_id == creds.customer_id
    assert client.developer_auth_token_id == creds.developer_auth_token_id
    assert client.developer_auth_token == creds.developer_auth_token
    assert client.customer_auth_token == creds.customer_auth_token
  end

  test "can sign requests with tokens correctly", %{server: server, url: url, creds: creds} do
    path = "/foo"
    signed_hash = Client.encode_request(creds, url <> path)

    Bypass.expect_once server, fn conn ->
      %Plug.Conn{req_headers: headers} = conn

      auth_header = Enum.find headers, fn({name, _value}) -> name == "x-api-authorization" end

      assert auth_header == {"x-api-authorization", signed_hash}

      Plug.Conn.resp(conn, 200, "")
    end

    {:ok, client} = Client.create(creds)

    Client.get_request(client, path, [version: "6.0"])
  end
end
