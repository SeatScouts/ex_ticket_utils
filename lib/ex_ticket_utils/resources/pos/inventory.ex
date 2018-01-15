defmodule ExTicketUtils.Pos.Inventory do
  import ExTicketUtils.Client, only: [put_request: 3, get_request: 3, post_request: 3]
  import ExTicketUtils.Helpers, only: [verify_params: 2]

  alias ExTicketUtils.Client

  def search(client = %Client{options: client_options}, params, options \\ []) do
    version = Keyword.get(options, :version, "v3")

    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge(options)

    case version do
      "v2" ->
        path = "/POS/Inventory"

        get_request(client, path, client_options)
      "v3" ->
        path = "/POS/Tickets/Search"

        post_request(client, path, client_options)
      _ -> raise "Unknown api version"
    end

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
