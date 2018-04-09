defmodule ExTicketUtils.Pos.InventoryTest do
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

  test "#v3 Pos.Inventory.search", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Tickets/Search" == conn.request_path
      assert "POST" == conn.method

      {:ok, encoded} =
        Poison.encode(%{
          "Items" => [%{"EventId" => "abcd-efgh"}],
          "Meta" => nil,
          "Page" => 1,
          "Records" => 1,
          "TotalPages" => 1
        })

      Plug.Conn.resp(conn, 200, encoded)
    end)

    {:ok, response} =
      ExTicketUtils.Pos.Inventory.search(client, %{"id" => "abcd-efgh"}, version: "v3")

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end

  test "#v3 Pos.Inventory.set_broadcast", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Tickets/BroadcastData" == conn.request_path
      assert "PUT" == conn.method

      {:ok, encoded} =
        Poison.encode(%{
          "Items" => [%{"EventId" => "abcd-efgh"}],
          "Meta" => nil,
          "Page" => 1,
          "Records" => 1,
          "TotalPages" => 1
        })

      Plug.Conn.resp(conn, 200, encoded)
    end)

    {:ok, response} =
      ExTicketUtils.Pos.Inventory.set_broadcast(client, %{"id" => "abcd-efgh"}, version: "v3")

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end

  test "#v3 Pos.Inventory.set_sell_price", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/POS/Tickets/abcd-efgh/SellPrice" == conn.request_path
      assert "PUT" == conn.method

      {:ok, encoded} =
        Poison.encode(%{
          "Items" => [%{"EventId" => "abcd-efgh"}],
          "Meta" => nil,
          "Page" => 1,
          "Records" => 1,
          "TotalPages" => 1
        })

      Plug.Conn.resp(conn, 200, encoded)
    end)

    {:ok, response} =
      ExTicketUtils.Pos.Inventory.set_sell_price(client, %{"Id" => "abcd-efgh"}, version: "v3")

    %{"Items" => [%{"EventId" => event_id}]} = response

    assert event_id == "abcd-efgh"
  end
end
