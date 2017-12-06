defmodule ExTicketUtils.Client do
  use HTTPoison.Base

  alias ExTicketUtils.{Client}
  alias HTTPoison.Response

  @default_options [recv_timeout: 15000]
  @domain Application.get_env(:ex_ticket_utils, :domain, "ticketutilssandbox.com")

  defstruct [:api_token, :api_secret, :options]

  def create(creds = %{api_token: _api_token, api_secret: _api_secret}, options \\ []) do
    creds = Map.put(creds, :options, create_options(options))

    {:ok, struct(Client, Map.to_list(creds))}
  end

  defp create_options(options) do
    Keyword.merge(@default_options, options)
  end

  def get_request(creds, path, options \\ []) do
    make_request(:get, creds, path, options) |> handle_response
  end

  def post_request(creds, path, options \\ []) do
    make_request(:post, creds, path, options) |> handle_response
  end

  defp handle_response(response) do
    case response do
      {:ok, %Response{body: body, status_code: 200}} -> Poison.decode(body)
      {:ok, response = %Response{status_code: 400}} -> {:error, :bad_request, response}
      {:ok, response = %Response{status_code: 403}} -> {:error, :forbidden, response}
      {:ok, response = %Response{status_code: 404}} -> {:error, :not_found, response}
      {:ok, response = %Response{status_code: 500}} -> {:error, :internal_server_error, response}
      {:error, raw = %HTTPoison.Error{reason: reason}} -> {:error, reason, raw}
      {_, response} -> {:error, :unknown, response}
    end
  end

  defp make_request(type, creds, path, options) do
    {version, options} = Keyword.pop(options, :version, "v3")

    url = build_url(path, version)

    {params, options} = Keyword.pop(options, :params, %{})

    {params, url} = process_params(params, url, type)

    headers = process_headers(creds, url)

    if options[:debug] do
      IO.inspect [
        api_token: creds.api_token,
        api_secret: creds.api_secret,
        url: url,
        params: params,
        headers: headers
      ]
    end

    request(type, url, params, headers, options)
  end

  defp process_params(params, url, :get) do
    url = cond do
      Enum.empty?(params)  -> url
      URI.parse(url).query                   -> url <> "&" <> URI.encode_query(params)
      true                                   -> url <> "?" <> URI.encode_query(params)
    end

    {"", url}
  end

  defp process_params(params, url, :post) do
    {{:form, Enum.into(params, [])}, url}
  end

  defp build_url(path, version) do
    host = case version do
      "v2" -> Enum.join(["apiv2", @domain], ".")
      "v3" -> Enum.join(["api", @domain], ".")
      _ -> raise "Invalid version specified"
    end

    URI.to_string(%URI{scheme: "https", host: host, path: path})
  end

  defp process_headers(creds, url) do
    %{api_token: api_token} = creds
    signature = encode_request(creds, url)

    [
      "X-Signature": signature,
      "X-Token": api_token,
      "Accept": "application/json"
    ]
  end

  def encode_request(creds, url) do
    %{api_secret: api_secret} = creds

    url = URI.parse(url)

    :crypto.hmac(:sha256, api_secret, url.path) |> Base.encode64
  end
end
