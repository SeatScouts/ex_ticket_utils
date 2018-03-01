defmodule ExTicketUtils.Pos.Invoices.LineItems do
  import ExTicketUtils.Client, only: [get_request: 3, post_request: 3]
  import ExTicketUtils.Helpers, only: [merge_options: 4]

  def search(client, params, options \\ []) do
    version = Keyword.get(options, :version, "v2")

    client_options = merge_options(client, params, version, options)

    case version do
      "v2" ->
        path = "/POS/Invoices/LineItems"

        get_request(client, path, client_options)
      "v3" ->
        path = "POS/Sales/InvoiceItems/Search"

        post_request(client, path, client_options)
      _ -> raise "Unknown api version"
    end
  end
end
