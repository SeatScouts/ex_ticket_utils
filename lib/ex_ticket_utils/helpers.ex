defmodule ExTicketUtils.Helpers do
  alias ExTicketUtils.Client

  def verify_params(params, required_keys) do
    Enum.each required_keys, fn (key) ->
      if !params[key] do
        raise "Requires #{key} params"
      end
    end
  end

  def merge_options(%Client{options: client_options}, params, version, fn_options) do
    client_options
    |> Keyword.merge([params: params])
    |> Keyword.merge([version: version])
    |> Keyword.merge(fn_options)
  end

  def join_lists(params), do: Enum.reduce(params, %{}, fn ({index, value}, acc) -> Map.put(acc, index, join_list(value)) end)
  defp join_list(value) when is_list(value), do: Enum.join(value, ",")
  defp join_list(param), do: param
end
