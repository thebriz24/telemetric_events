import Config

config :logger,
  translators: [
    {TelemetricEvents.Logger.JSONTranslator, :translate},
    {Logger.Translator, :translate}
  ],
  console: [
    format: {TelemetricEvents.Logger.JSONFormatter, :format}
  ]
