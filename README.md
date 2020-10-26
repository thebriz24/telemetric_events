# TelemetricEvents

Changes the logging and metric paradigm to event emission rather than the 
modules taking care of their own logging and metrics. Uses [:telemetry](https://hexdocs.pm/telemetry/)
to receive the events and route them to different handlers. Combines [Logger](https://hexdocs.pm/logger/Logger.html)
and [Prometheus](https://hexdocs.pm/prometheus_ex/Prometheus.html) to process 
the events.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `telemetric_events` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetric_events, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/telemetric_events](https://hexdocs.pm/telemetric_events).

## Usage

There is a setup function: `setup_handler/1`. The argument is a module. See 
the Prometheus section for more information.

The main function you will be interacting with is `emit_event/2`. It simply makes 
use of `:telemetry`. 

`:telemetry` routes events to their handlers based on the event name. This 
package uses the pattern `app`, `type`, `action` for the event name. So for 
example, if you had an app called `blog_collector` that had a webhook that 
listened for new blogs being published, normalized the text, and then inserted
the blog into a database, you could feasibly have three events from that process
(or more or less). That would mean you'd need three event names: 
`[:blog_collector, :blog, :received]`, `[:blog_collector, :blog, :normalized]`, 
`[:blog_collector, :blog, :inserted]`.

The configuration for the metrics will also follow this naming pattern:
```
config :blog_collector, blog: [
  recieved: metric,
  normalized: metric,
  inserted: metric
]
```
I will come back to further metric setup soon, but first I will finish up 
`:telemetry` usage and then touch on `Logger` usage.

`:telemetry` will also be given a map alongside the event name. The map must have
the values that will be placed in the configured Prometheus labels for that event
(more on that later). The map can have any other number of key-value pairs that 
won't effect the metrics, they will simply be added to the logs. There will also
be two forms you can use for `emit_event/2`: full event name or just the type 
with the action as part of the map. 
`emit_event([:blog_collector, :blog, :received], any_map)` and 
`emit_event(:blog, %{any_map | action: "received"})` respectively.

Note: If an error is raised by the functions that are given to :telemetry, the 
handler will detach. I will try to mitigate that as much as possible, but until 
:telemetry has a way of broadcasting that they've detached the handler, 
mitigation is all I can do.

Logging an event just uses the standard `Logger` package. In the future (as 
needed) I will support other logging packages, but to be honest I don't know of 
anyone that uses anything other than `Logger`. However, if you need `Logger` to 
perform differently than the way I configure it in this package and your 
configuration disrupts the performance of this package, please submit an 
[issue](https://github.com/thebriz24/telemetric_events/issues/new) and I will 
try to accommodate.

I am presupposing an ELK stack implementation of log collection because, to date,
that has been the best process for easily used logs. Therefore, logs will be 
emitted as maps/JSON. Even `Logger` statements outside of the event will be 
wrapped in a map through `Logger`'s configuration. 

E.g. 
```
{
  "app": "blog_collector",
  "type": "blog",
  "action": "received",
  "payload_size": 239,
  "blog_subdomain": "example-health-tips",
  "message": "Recieved blog post with title: \"Fit and Fabulous in 15 days!\"",
  "timestamp": "2015-06-24T05:04:13.293Z"
}
```

Note: Version 0.1.0 won't have the logging implemented. I'm working on an app
that will include this package. It's not at a place where it's ready to 
implement this logging strategy. So to get it up and going, I'm skipping 
logging for now.

`Prometheus` is more hands on in it's setup. Take the configuration from above;
where it says `metric`, you can put in a few options. Each option corresponds 
to a `Prometheus` metric type. Each has a different tuple for 
configuration:

1. `{:counter, name :: atom(), labels :: [atoms()], help :: String.t()}`
2. `{:gauge, name :: atom(), labels :: [atoms()], help :: String.t()}` 
3. `{:histogram, name :: atom(), labels :: [atoms()], buckets :: [integer()], help :: String.t()}` 
4. `{:summary, name :: atom(), labels :: [atoms()], quantiles :: [integer()], help :: String.t()}` 

Note: Last time I checked the summary metric from 
[:prometheus](https://hex.pm/packages/prometheus) didn't work properly, but 
counters, gauges and histograms are available. 

Remember that anything you put in the labels for the metric must have values 
under that key in the map passed to `emit_event/2`. E.g. if you have 
`:payload_size` as a label you must have `payload_size: some_int` in the map. 
If you just want logging and not metrics then just don't define any metrics for 
that event name.

Then all you need is a way for Prometheus to reach your server.
[PlugExporter](https://hexdocs.pm/prometheus_plugs/Prometheus.PlugExporter.html)
will let you configure an endpoint that Prometheus will query to collect the 
metrics.

And that's about it. As long as your metrics and event match up it should just 
work. If anything is wrong, please write an issue for it. I am planning on 
actively developing this project.
