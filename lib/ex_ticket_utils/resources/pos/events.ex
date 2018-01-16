defmodule ExTicketUtils.Pos.Events do
  import ExTicketUtils.Client, only: [get_request: 3]
  import ExTicketUtils.Helpers, only: [merge_options: 4]

  def fetch(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v2")

    client_options = merge_options(client, params, version, options)

    path = "/POS/Events"

    get_request(client, path, client_options)
  end
end
