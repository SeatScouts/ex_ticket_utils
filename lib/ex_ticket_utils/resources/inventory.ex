defmodule ExTicketUtils.Inventory do
  import ExTicketUtils.Client, only: [post_request: 3]

  alias ExTicketUtils.Client

  def search(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/Tickets/Search"

    post_request(client, path, client_options)
  end
end
