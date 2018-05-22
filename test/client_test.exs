defmodule ExTicketUtils.ClientTest do
  use ExUnit.Case

  alias ExTicketUtils.Client

  setup do
    server = Bypass.open()

    Application.put_env(:ex_ticket_utils, :url, "http://localhost:#{server.port}")

    creds = %{
      api_token: "12345",
      api_secret: "67890"
    }

    {:ok, server: server, creds: creds}
  end

  test "can create a client", %{creds: creds} do
    {:ok, client} = Client.create(creds)

    assert client.api_token == creds.api_token
    assert client.api_secret == creds.api_secret
  end

  test "can sign requests with tokens correctly", %{server: server, creds: creds} do
    path = "/foo?test=12345"
    signed_hash = Client.encode_request(creds, path)

    Bypass.expect_once(server, fn conn ->
      %Plug.Conn{req_headers: headers} = conn

      signature = Enum.find(headers, fn {name, _value} -> name == "x-signature" end)
      token = Enum.find(headers, fn {name, _value} -> name == "x-token" end)

      assert signature == {"x-signature", signed_hash}
      assert token == {"x-token", creds[:api_token]}

      Plug.Conn.resp(conn, 200, "")
    end)

    {:ok, client} = Client.create(creds)

    Client.get_request(client, path)
  end

  test "can handle 400 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 400, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :bad_request, _response} = Client.get_request(client, path)
  end

  test "can handle 401 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 401, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :invalid_credentials, _response} = Client.get_request(client, path)
  end

  test "can handle 403 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 403, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :forbidden, _response} = Client.get_request(client, path)
  end

  test "can handle 404 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 404, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :not_found, _response} = Client.get_request(client, path)
  end

  test "can handle 409 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 409, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :conflict, _response} = Client.get_request(client, path)
  end

  test "can handle 429 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 429, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :too_many_requests, _response} = Client.get_request(client, path)
  end

  test "can handle 500 errors", %{server: server, creds: creds} do
    path = "/foo?test=12345"

    Bypass.expect_once(server, fn conn ->
      Plug.Conn.resp(conn, 500, "")
    end)

    {:ok, client} = Client.create(creds)

    {:error, :internal_server_error, _response} = Client.get_request(client, path)
  end
end
