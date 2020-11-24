defmodule TelemetricEvents.Logger.JSONFormatter do
  @moduledoc """
  Attempts to encode the log message with Jason. If it's not a map then will place
  the message in a map under the `:message` key. If using JSON logging, you must
  add this formatter to the list of formatters in the logger console config. I.E.
  ```
  config :logger,
    console: [format: {TelemetricEvents.Logger.JSONFormatter, :format}]
  ```
  """

  @spec format(atom(), any(), :calendar.datetime(), Keyword.t()) :: String.t()
  def format(level, message, timestamp, metadata) do
    metadata
    |> ensure_map()
    |> Map.merge(ensure_map(message))
    |> Map.put_new("level", level)
    |> Map.put_new("timestamp", erl_to_iso8601!(timestamp))
    |> Jason.encode!()
    |> Kernel.<>("\n")
  rescue
    _ -> "could not format with Jason: #{inspect({level, message, metadata})}\n"
  end

  defp ensure_map([]), do: %{}
  defp ensure_map(map) when is_map(map), do: map

  defp ensure_map(string) when is_binary(string) do
    case Jason.decode(string) do
      {:ok, map} when is_map(map) -> map
      {:ok, other} -> %{message: other}
      {:error, %Jason.DecodeError{data: ""}} -> %{message: nil}
      {:error, _} -> %{message: string}
    end
  end

  defp ensure_map(list) when is_list(list), do: %{message: List.to_string(list)}
  defp ensure_map(other), do: %{message: other}

  defp erl_to_iso8601!({{_, _, _}, {_, _, _}} = datetime) do
    datetime
    |> NaiveDateTime.from_erl!()
    |> NaiveDateTime.to_iso8601()
  end

  # Because Erlang seems to have changed their :calendar.datetime format
  defp erl_to_iso8601!({{year, month, day}, {hour, minute, second, _}}) do
    year
    |> NaiveDateTime.new!(month, day, hour, minute, second)
    |> NaiveDateTime.to_iso8601()
  end
end
