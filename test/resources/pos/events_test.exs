defmodule ExTicketUtils.Pos.EventsTest do
  use ExUnit.Case

  alias ExTicketUtils.Client

  setup do
    server = Bypass.open()

    Application.put_env(:ex_ticket_utils, :url, "http://localhost:#{server.port}")

    client = %Client{
      api_token: "12345",
      api_secret: "67890",
      options: []
    }

    {:ok, server: server, client: client}
  end

  test "#v2 Pos.Events.fetch", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Events" == conn.request_path
      assert "GET" == conn.method

      {:ok, encoded} =
        Jason.encode(%{
          "Items" => [%{"EventId" => "abcd-efgh"}],
          "Meta" => nil,
          "Page" => 1,
          "Records" => 1,
          "TotalPages" => 1
        })

      Plug.Conn.resp(conn, 200, encoded)
    end)

    {:ok, response} = ExTicketUtils.Pos.Events.fetch(client, %{"id" => "abcd-efgh"})

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end

  test "#v2 handle errors in Pos.Events", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Events" == conn.request_path
      assert "GET" == conn.method

      {:ok, encoded} =
        Jason.encode(%{
          "message" => "Broken Server"
        })

      Plug.Conn.resp(conn, 500, encoded)
    end)

    {:error, :internal_server_error, _response} =
      ExTicketUtils.Pos.Events.fetch(client, %{"id" => "abcd-efgh"})
  end
end
