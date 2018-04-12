defmodule ExTicketUtils.Pos.Inventory do
  import ExTicketUtils.Client, only: [put_request: 3, get_request: 3, post_request: 3]
  import ExTicketUtils.Helpers, only: [verify_params: 2, merge_options: 4]

  def search(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v3")

    client_options = merge_options(client, params, version, options)

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

  def set_broadcast(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v3")

    client_options = merge_options(client, params, version, options)

    case version do
      "v2" ->
        path = "/POS/Inventory/UpdateTicket"

        post_request(client, path, client_options)
      "v3" ->
        path = "/POS/Tickets/BroadcastData"

        put_request(client, path, client_options)
      _ -> raise "Unknown api version"
    end
  end

  def set_sell_price(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v3")

    case version do
      "v2" ->
        client_options = merge_options(client, params, version, options)

        path = "/POS/Inventory/UpdateTicket"

        post_request(client, path, client_options)
      "v3" ->
        verify_params(params, ["Id"])

        {lot_id, params} = Map.pop(params, "Id")

        client_options = merge_options(client, params, version, options)

        path = "/POS/Tickets/#{lot_id}/SellPrice"

        put_request(client, path, client_options)
      _ -> raise "Unknown api version"
    end
  end

  def mass_update(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v3")

    case version do
      "v2" ->
        client_options = merge_options(client, params, version, options)

        path = "/POS/Inventory/UpdateTickets"

        post_request(client, path, client_options)
      "v3" ->
        verify_params(params, ["Id"])

        {lot_id, params} = Map.pop(params, "Id")

        client_options = merge_options(client, params, version, options)

        path = "/POS/Tickets/#{lot_id}/SellPrice"

        put_request(client, path, client_options)
      _ -> raise "Unknown api version"
    end
  end
end
