defmodule TelemetricEvents.Prometheus do
  @moduledoc false

  @app Application.compile_env!(:telemetric_events, :otp_app)
  @modules %{
    counter: Prometheus.Metric.Counter,
    gauge: Prometheus.Metric.Gauge,
    histogram: Prometheus.Metric.Histogram,
    summary: Prometheus.Metric.Summary
  }

  defmacro __using__(_args) do
    caller = __CALLER__.module

    quote do
      def setup do
        unquote(
          @app
          |> Application.get_env(:metrics, [])
          |> Enum.map(fn kv -> drill_down(kv, &declare_metric(&1, &2, caller)) end)
        )
      end

      unquote(
        @app
        |> Application.get_env(:metrics, [])
        |> Enum.map(fn kv -> drill_down(kv, &declare_observation(&1, &2, caller)) end)
      )
    end
  end

  defp drill_down({type, actions}, function) when is_list(actions),
    do: Enum.map(actions, &drill_down(&1, type, function))

  defp drill_down({action, metric}, type, function) when is_tuple(metric),
    do: function.([@app, type, action], metric)

  defguardp is_valid_metric(name, labels, help)
            when is_atom(name) and is_list(labels) and is_binary(help)

  defguardp is_valid_metric(name, labels, buckets, help)
            when is_valid_metric(name, labels, help) and is_list(buckets)

  defguardp is_valid_metric(metric)
            when is_valid_metric(elem(metric, 1), elem(metric, 2), elem(metric, 3))

  defp declare_metric(_event_name, {module, name, labels, help}, _caller)
       when is_valid_metric(name, labels, help) do
    quote bind_quoted: [module: convert_metric(module), name: name, labels: labels, help: help] do
      module.new(name: name, labels: labels, help: help)
    end
  end

  defp declare_metric(_event_name, {module, name, labels, buckets, help}, _caller)
       when is_valid_metric(name, labels, buckets, help) do
    quote bind_quoted: [
            module: convert_metric(module),
            name: name,
            labels: labels,
            buckets: buckets,
            help: help
          ] do
      module.new(name: name, labels: labels, buckets: buckets, help: help)
    end
  end

  defp declare_observation(event_name, {:counter, _, _, _} = metric, caller)
       when is_valid_metric(metric),
       do:
         declare_observation(
           event_name,
           convert_metric(metric),
           create_prefix(:inc, caller),
           caller
         )

  defp declare_observation(event_name, {:gauge, _, _, _} = metric, caller)
       when is_valid_metric(metric),
       do:
         Enum.map(
           [:inc, :dec, :set],
           &declare_observation(
             event_name,
             convert_metric(metric),
             create_prefix(&1, caller),
             caller
           )
         )

  defp declare_observation(event_name, {:histogram, name, labels, buckets, help} = metric, caller)
       when is_valid_metric(name, labels, buckets, help),
       do:
         declare_observation(
           event_name,
           convert_metric(metric),
           create_prefix(:observe, caller),
           caller
         )

  defp declare_observation(event_name, {:summary, _, _, _} = metric, caller)
       when is_valid_metric(metric),
       do:
         declare_observation(
           event_name,
           convert_metric(metric),
           create_prefix(:observe, caller),
           caller
         )

  defp declare_observation(_event_name, metric, _caller),
    do:
      raise(CompileError,
        file: __ENV__.file,
        line: __ENV__.line,
        description:
          "Attempting to declare a metric that doesn't follow the established pattern: #{
            inspect(metric)
          }."
      )

  defp declare_observation(event_name, {module, name, labels}, {call, key} = prefix, caller) do
    quote do
      def observe(unquote(event_name), unquote(format_pattern_match(labels, prefix, caller))) do
        unquote(module).unquote(call)(
          [name: unquote(name), labels: unquote(format_argument(labels, caller))],
          unquote(key)
        )
      end
    end
  end

  defp declare_observation(event_name, {module, name, labels}, {call, key, default}, caller) do
    prefix = {call, key}

    quote do
      def observe(unquote(event_name), unquote(format_pattern_match(labels, prefix, caller))) do
        unquote(module).unquote(call)(
          [name: unquote(name), labels: unquote(format_argument(labels, caller))],
          unquote(key)
        )
      end

      def observe(unquote(event_name), unquote(format_pattern_match(labels, caller))) do
        unquote(module).unquote(call)(
          [name: unquote(name), labels: unquote(format_argument(labels, caller))],
          unquote(default)
        )
      end
    end
  end

  defp convert_metric(module) when is_atom(module), do: @modules[module]

  defp convert_metric({module, name, labels, _buckets, _help}),
    do: {convert_metric(module), name, labels}

  defp convert_metric({module, name, labels, _help}), do: {convert_metric(module), name, labels}

  defp create_prefix(:observe, caller), do: {:observe, Macro.var(:observation, caller)}

  defp create_prefix(name, caller) when name in [:inc, :dec],
    do: {name, Macro.var(name, caller), 1}

  defp create_prefix(name, caller) when is_atom(name), do: {name, Macro.var(name, caller)}

  defp format_pattern_match(labels, caller),
    do: {:%{}, [], Enum.map(labels, &{&1, Macro.var(&1, caller)})}

  defp format_pattern_match(labels, prefix, caller),
    do: {:%{}, [], [prefix | Enum.map(labels, &{&1, Macro.var(&1, caller)})]}

  defp format_argument(labels, caller), do: Enum.map(labels, &Macro.var(&1, caller))
end
