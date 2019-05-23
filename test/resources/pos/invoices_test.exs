defmodule ExTicketUtils.Pos.InvoicesTest do
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

  test "#v2 Pos.Inventory.search", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Invoices" == conn.request_path
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

    {:ok, response} = ExTicketUtils.Pos.Invoices.search(client, %{"Id" => 12345}, version: "v2")

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end

  test "#v3 Pos.Inventory.search", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Sales/Invoices/Search" == conn.request_path
      assert "POST" == conn.method

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

    {:ok, response} = ExTicketUtils.Pos.Invoices.search(client, %{"Id" => 12345}, version: "v3")

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end
end
