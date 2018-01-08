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
    make_request(:get, creds, path, options) |> handle_response
  end

  def post_request(creds, path, options \\ []) do
    make_request(:post, creds, path, options) |> handle_response
  end

  def put_request(creds, path, options \\ []) do
    make_request(:put, creds, path, options) |> handle_response
  end

  defp handle_response(response) do
    case response do
      {:ok, %Response{body: body, status_code: 200}} -> Poison.decode(body)
      {:ok, response = %Response{status_code: 400}} ->
        case Poison.decode(response.body) do
          {:ok, json} ->
            message = json["Message"]

            if message do
              case Regex.match?(~r/Invalid/, message) do
                true -> {:ok, %{"Items" => [], "Records" => 0, "TotalPages" => 1}}
                false -> {:error, :bad_request, response}
              end
            else
              {:error, :bad_request, response}
            end
          {:error, _reason} -> {:error, :bad_request, response}
        end
      {:ok, response = %Response{status_code: 403}} -> {:error, :forbidden, response}
      {:ok, response = %Response{status_code: 404}} -> {:error, :not_found, response}
      {:ok, response = %Response{status_code: 500}} -> {:error, :internal_server_error, response}
      {:error, raw = %HTTPoison.Error{reason: reason}} -> {:error, reason, raw}
      {_, response} -> {:error, :unknown, response}
    end
  end

  defp make_request(type, creds, path, options) do
    {version, options} = Keyword.pop(options, :version, "v3")
    {params, options} = Keyword.pop(options, :params, %{})

    {body, path} = process_params(params, type, path)

    headers = process_headers(creds, path, version)

    url = build_url(path, version)

    if options[:debug] do
      IO.inspect [
        api_token: creds.api_token,
        api_secret: creds.api_secret,
        url: url,
        signed_path: path,
        body: body,
        headers: headers
      ]
    end

    request(type, url, body, headers, options)
  end

  defp process_params(params, :get, path) do

    path = cond do
      Enum.empty?(params)  -> path
      URI.parse(path).query -> path <> "&" <> URI.encode_query(params)
      true                 -> path <> "?" <> URI.encode_query(params)
    end

    {"", path}
  end

  defp process_params(params, :post, path) do
    {{:form, Enum.into(params, [])}, path}
  end

  defp process_params(params, :put, path) do
    {Poison.encode!(params), path}
  end

  defp build_url(path, version) do
    url = Application.get_env(:ex_ticket_utils, :url, nil)
    is_sandbox = Application.get_env(:ex_ticket_utils, :sandbox, true)

    case url do
      nil ->
        host = case is_sandbox do
          true ->
            case version do
              "v2" -> "apiv2.ticketutilssandbox.com"
              _ -> "api.ticketutilssandbox.com"
            end
          false ->
            case version do
              "v2" -> "api.ticketutils.net"
              _ -> "api.ticketutils.com"
            end
        end

        URI.to_string(%URI{scheme: "https", host: host, path: path})

      url ->
        url = url
        |> URI.parse
        |> Map.put(:path, path)
        |> URI.to_string
    end
  end

  defp process_headers(creds, path, version) do
    extras = case version do
      "v2" -> ["X-API-Version": 2]
      _ -> []
    end

    %{api_token: api_token} = creds

    signature = encode_request(creds, path)

    Keyword.merge([
      "X-Signature": signature,
      "X-Token": api_token,
      "Content-Type": "application/json",
      "Accept": "application/json"
    ], extras)
  end

  def encode_request(creds, path) do
    %{api_secret: api_secret} = creds

    :crypto.hmac(:sha256, api_secret, path) |> Base.encode64
  end
end
