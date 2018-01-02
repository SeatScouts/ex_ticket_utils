defmodule ExTicketUtils.Inventory do
  import ExTicketUtils.Client, only: [put_request: 3, post_request: 3]
  import ExTicketUtils.Helpers, only: [verify_params: 2]

  alias ExTicketUtils.Client

  def search(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/Tickets/Search"

    post_request(client, path, client_options)
  end

  def set_broadcast(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/Tickets/BroadcastData"

    put_request(client, path, client_options)
  end

  def set_sell_price(client = %Client{options: client_options}, params, options \\ []) do
    verify_params(params, ["Id"])

    {lot_id, params} = Map.pop(params, "Id")

    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/Tickets/#{lot_id}/SellPrice"

    put_request(client, path, client_options)
  end
end
