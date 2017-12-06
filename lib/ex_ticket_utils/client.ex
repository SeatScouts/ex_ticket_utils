defmodule ExTicketUtils.Client do
  use HTTPoison.Base

  alias ExTicketUtils.{Client}
  alias HTTPoison.Response

  @default_options [recv_timeout: 15000]

  defstruct [:api_token, :api_secret, :options]

  def create(creds = %{api_token: _api_token, api_secret: _api_secret}, options \\ []) do
    creds = Map.put(creds, :options, create_options(options))

    {:ok, struct(Client, Map.to_list(creds))}
  end

  defp create_options(options) do
    Keyword.merge(@default_options, options)
  end

  def get_request(creds, path, options \\ []) do
    host = Application.get_env(:ex_ticket_utils, :base_url, "https://api.ticketutilssandbox.com")
    url = build_url(path, [host: host])

    handle_response(make_request(:get, creds, url, options))
  end

  def post_request(creds, path, options \\ []) do
    host = Application.get_env(:ex_ticket_utils, :base_url, "https://api.ticketutilssandbox.com")
    url = build_url(path, [host: host])

    handle_response(make_request(:post, creds, url, options))
  end

  defp handle_response(response) do
    case response do
      {:ok, %Response{body: body, status_code: 200}} -> Poison.decode(body)
      {:ok, response = %Response{status_code: 400}} -> {:error, :bad_request, response}
      {:ok, response = %Response{status_code: 403}} -> {:error, :forbidden, response}
      {:ok, response = %Response{status_code: 404}} -> {:error, :not_found, response}
      {:error, raw = %HTTPoison.Error{reason: reason}} -> {:error, reason, raw}
      {_, response} -> {:error, :unknown, response}
    end

  end

  defp make_request(:get, creds, url, options) do
    params = Keyword.get(options, :params, %{})

    url = cond do
      Enum.empty?(params)  -> url
      URI.parse(url).query                   -> url <> "&" <> URI.encode_query(options[:params])
      true                                   -> url <> "?" <> URI.encode_query(options[:params])
    end

    headers = process_headers(creds, url)

    {_params, options} = Keyword.pop(options, :params)

    request(:get, url, "", headers, options)
  end

  defp make_request(:post, creds, url, options) do
    params = Keyword.get(options, :params, %{})

    headers = process_headers(creds, url)

    {params, options} = Keyword.pop(options, :params)

    params = Enum.into(params, [])
    IO.inspect [:post, url, {:form, params}, headers, options]
    request(:post, url, {:form, params}, headers, options)
  end

  defp build_url(url, [host: host]), do: Enum.join([host, url])

  defp process_headers(creds, url) do
    %{api_token: api_token} = creds
    signature = encode_request(creds, url)

    headers = [
      "X-Signature": signature,
      "X-Token": api_token,
      "Accept": "application/json"
    ]

    IO.inspect [creds, url, headers]


    headers
  end

  def encode_request(creds, url) do
    %{api_secret: api_secret} = creds

    url = URI.parse(url)

    :crypto.hmac(:sha256, api_secret, url.path) |> Base.encode64
  end
end
