defmodule ExTicketUtils.Client do
  use HTTPoison.Base

  alias ExTicketUtils.{Client}
  alias HTTPoison.Response

  @default_options [recv_timeout: 60000]

  defstruct [:api_token, :api_secret, :options]

  def create(creds = %{api_token: _api_token, api_secret: _api_secret}, options \\ []) do
    creds = Map.put(creds, :options, create_options(options))

    {:ok, struct(Client, Map.to_list(creds))}
  end

  defp create_options(options) do
    Keyword.merge(@default_options, options)
  end

  def get_request(creds, path, options \\ []) do
    make_request(:get, creds, path, options) |> handle_response(options)
  end

  def post_request(creds, path, options \\ []) do
    make_request(:post, creds, path, options) |> handle_response(options)
  end

  def put_request(creds, path, options \\ []) do
    make_request(:put, creds, path, options) |> handle_response(options)
  end

  defp handle_response(response, options) do
    case response do
      {:ok, %Response{body: body, status_code: 200}} ->
        Poison.decode(body)

      {:ok, response = %Response{status_code: 400}} ->
        case Poison.decode(response.body) do
          {:ok, %{"Message" => message}} ->
            case options[:version] do
              "v2" ->
                cond do
                  Regex.match?(~r/Result not found/, message) ->
                    {:ok,
                     %{
                       "Items" => [],
                       "Pagination" => %{
                         "CurrentPage" => 1,
                         "TotalPages" => 1,
                         "TotalResults" => 0
                       }
                     }}

                  true ->
                    {:error, :bad_request, response}
                end

              _ ->
                {:error, :bad_request, response}
            end

          {:error, reason} ->
            {:error, :bad_request, %{"reason" => reason}}
        end

      {:ok, response = %Response{status_code: 403}} ->
        {:error, :forbidden, response}

      {:ok, response = %Response{status_code: 404}} ->
        {:error, :not_found, response}

      {:ok, response = %Response{status_code: 429}} ->
        {:error, :too_many_requests, response}

      {:ok, response = %Response{status_code: 409}} ->
        {:error, :conflict, response}

      {:ok, response = %Response{status_code: 500}} ->
        {:error, :internal_server_error, response}

      {:error, raw = %HTTPoison.Error{reason: reason}} ->
        {:error, reason, raw}

      {_, response} ->
        {:error, :unknown, response}
    end
  end

  defp make_request(type, creds, path, options) do
    {version, options} = Keyword.pop(options, :version, "v3")
    {params, options} = Keyword.pop(options, :params, %{})

    {body, path} = process_params(params, type, path)

    headers = process_headers(creds, path, version)

    url = build_url(path, version)

    if options[:debug] do
      IO.inspect(
        api_token: creds.api_token,
        api_secret: creds.api_secret,
        url: url,
        signed_path: path,
        body: body,
        headers: headers,
        options: options
      )
    end

    request(type, url, body, headers, options)
  end

  defp process_params(params, :get, path) do
    path =
      cond do
        Enum.empty?(params) -> path
        URI.parse(path).query -> path <> "&" <> URI.encode_query(params)
        true -> path <> "?" <> URI.encode_query(params)
      end

    {"", path}
  end

  defp process_params(params, :post, path), do: {Poison.encode!(params), path}
  defp process_params(params, :put, path), do: {Poison.encode!(params), path}

  defp build_url(path, version) do
    url = Application.get_env(:ex_ticket_utils, :url, nil)

    case url do
      nil ->
        host =
          case version do
            "v1" -> "api.ticketutils.net"
            "v2" -> "api.ticketutils.net"
            _ -> "api.ticketutils.com"
          end

        URI.to_string(%URI{scheme: "https", host: host, path: path})

      url ->
        url
        |> URI.parse()
        |> Map.put(:path, path)
        |> URI.to_string()
    end
  end

  defp process_headers(creds, path, version) do
    extras =
      case version do
        "v1" -> ["X-API-Version": 1]
        "v2" -> ["X-API-Version": 2]
        "v3" -> ["X-API-Version": 3]
        _ -> []
      end

    %{api_token: api_token} = creds

    signature = encode_request(creds, path)

    Keyword.merge(
      [
        "X-Signature": signature,
        "X-Token": api_token,
        "Content-Type": "application/json; charset=utf-8",
        Connection: "Keep-Alive",
        Accept: "application/json"
      ],
      extras
    )
  end

  def encode_request(creds, path) do
    %{api_secret: api_secret} = creds

    :crypto.hmac(:sha256, api_secret, path) |> Base.encode64()
  end
end
