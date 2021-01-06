import Config

config :logger,
  backends: [TelemetricEvents.Logger.JSONBackend],
  translators: [
    {TelemetricEvents.Logger.JSONTranslator, :translate},
    {Logger.Translator, :translate}
  ]

config :example,
  metrics: [
    messages: [
      received:
        {:counter, :received_message_count, [:sender],
         "Counts number of messages received separated on sender"},
      sent:
        {:counter, :sent_message_count, [:recipient],
         "Counts number of messages sent separated on recipient"}
    ],
    responses: [
      received:
        {:histogram, :received_response_duration_milliseconds, [:recipient], [50, 100, 500, 1000],
         "Buckets the time a sent message takes to round-robin to the recipient"}
    ]
  ]

if Mix.env() == :test, do: import_config("test.exs")
