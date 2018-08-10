defmodule ExTicketUtils.EventCatalog.Categories do
  import ExTicketUtils.Client, only: [get_request: 3]
  import ExTicketUtils.Helpers, only: [merge_options: 4]

  def fetch(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v1")

    client_options = merge_options(client, params, version, options)

    path = "/EventCatalog/Categories"

    get_request(client, path, client_options)
  end
end
