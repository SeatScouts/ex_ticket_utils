defmodule ExTicketUtils.Events do
  import ExTicketUtils.Client, only: [get_request: 3]
  import ExTicketUtils.Helpers, only: [verify_params: 2]

  alias ExTicketUtils.Client

  def fetch(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v2"])
    |> Keyword.merge(options)

    path = "/POS/Events"

    get_request(client, path, client_options)
  end

  def tags(client = %Client{options: client_options}, params, options \\ []) do
    verify_params(params, ["EventId"])

    {event_id, params} = Map.pop(params, "EventId")

    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/EventData/Events/#{event_id}/Tags"

    get_request(client, path, client_options)
  end

  def summary(client = %Client{options: client_options}, params, options \\ []) do
    client_options = client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: "v3"])
    |> Keyword.merge(options)

    path = "/POS/Tickets/EventSummary"

    get_request(client, path, client_options)
  end

end
