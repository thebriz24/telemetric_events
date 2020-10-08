# TelemetricEvents

Changes the logging and metric paradigm to event emission rather than the 
modules taking care of their own logging and metrics. Uses [:telemetry](https://hexdocs.pm/telemetry/)
to recieve the events and route them to different handlers. Combines [Logger](https://hexdocs.pm/logger/Logger.html)
and [Prometheus](https://hexdocs.pm/prometheus_ex/Prometheus.html) to process 
the events.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `telemetric_events` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetric_events, "~> 0.0.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/telemetric_events](https://hexdocs.pm/telemetric_events).

