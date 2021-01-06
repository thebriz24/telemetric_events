defmodule TelemetricEvents.Logger.JSONTranslator do
  @moduledoc false 

  # Uses Jason to encode a logged map. If using JSON logging, you must add this 
  # translator to the list of translators in the logger config. I.E. 
  # ```
  # config :logger,
  #   translators: [
  #     {TelemetricEvents.Logger.JSONTranslator, :translate}, 
  #     {Logger.Translator, :translate}
  #   ]
  # ```
  def translate(_min_level, _level, :report, {:logger, message}) when is_map(message) do
    {:ok, Jason.encode!(message)}
  rescue
    _ -> :none
  end

  def translate(min_level, level, :report, {:logger, message}) when is_list(message) do
    translate(min_level, level, :report, {:logger, Map.new(message)})
  rescue
    _ -> :none
  end

  def translate(_min_level, _level, _type, _message), do: :none
end
