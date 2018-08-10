defmodule ExTicketUtils.EventCatalog.CategoriesTest do
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

  test "#v1 EventCatalog.Categories.fetch", %{server: server, client: client} do
    Bypass.expect(server, fn conn ->
      assert "/EventCatalog/Categories" == conn.request_path
      assert "GET" == conn.method

      {:ok, encoded} =
        Poison.encode(%{
          "Items" => [%{
            "CategoryId" => "589abe30-8e9b-4d44-ba6f-b0a8eb1112f8",
            "Name" => "Acid Jazz",
            "Parent" => %{
              "CategoryId" => "fe8e8ddd-ab92-42da-b3e7-b5b115d31b77",
              "Name" => "Concert"
            }
          }],
          "Pagination" => %{
            "CurrentPage" => 1,
            "TotalPages" => 3,
            "TotalResults" => 237
          }
        })

      Plug.Conn.resp(conn, 200, encoded)
    end)

    {:ok, response} = ExTicketUtils.EventCatalog.Categories.fetch(client, %{"id" => "abcd-efgh"})

    %{"Items" => [%{"CategoryId" => category_id}]} = response

    assert category_id == "abcd-efgh"
  end
end
