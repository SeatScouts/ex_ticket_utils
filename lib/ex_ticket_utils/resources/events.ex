defmodule ExTicketUtils.Events do
  import ExTicketUtils.Client, only: [get_request: 3]

  alias ExTicketUtils.Client

  def fetch(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v2"])
    |> Keyword.merge(options)

    path = "/POS/Events"

    get_request(client, path, client_options)
  end

end
