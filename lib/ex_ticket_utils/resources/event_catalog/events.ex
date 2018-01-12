defmodule ExTicketUtils.EventCatalog.Events do
  import ExTicketUtils.Client, only: [get_request: 3]
  import ExTicketUtils.Helpers, only: [verify_params: 2]

  alias ExTicketUtils.Client

  def fetch(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v1"])
    |> Keyword.merge(options)

    path = "/EventCatalog/Events"

    get_request(client, path, client_options)
  end
end
