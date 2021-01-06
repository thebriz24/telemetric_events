defmodule TelemetricEventsTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias TelemetricEvents.TestModule

  setup :tear_down

  describe "setup_handler/1" do
    test "if bad module given" do
      assert_raise UndefinedFunctionError, fn ->
        TelemetricEvents.setup_handler(Bad)
      end
    end

    test "if the right module is given" do
      assert TelemetricEvents.setup_handler(TestModule) == :ok
    end
  end

  describe "emit_event/2" do
    test "unknown event_name fails silently due to :telemetry's design" do
      TelemetricEvents.setup_handler(TestModule)
      assert TelemetricEvents.emit_event([:example, :unknown, :unknown], %{})
    end

    test "metric doesn't exists fails silently due to :telemetry's design" do
      new = Application.get_env(:example, :metrics) |> Enum.concat(test: [test: []])
      Application.put_env(:example, :metrics, new)
      TelemetricEvents.emit_event([:example, :test, :test], %{})
    end

    test "map doesn't have all of the labels detaches the handler and logs" do
      TelemetricEvents.setup_handler(TestModule)

      assert capture_log(fn ->
               TelemetricEvents.emit_event([:example, :messages, :sent], %{})
             end) =~ "Handler :telemetric_events has failed and has been detached."
    end

    test "now logs in a json format" do
      TelemetricEvents.setup_handler(TestModule)

      assert capture_log(fn ->
               TelemetricEvents.emit_event([:example, :messages, :sent], %{
                 level: :error,
                 recipient: "anyone"
               })
             end) =~
               ~r/{"action":"sent","app":"example","level":"error","recipient":"anyone","timestamp":".{19}","type":"messages"}/
    end
  end

  defp tear_down(_context) do
    on_exit(fn ->
      :telemetry.detach(:telemetric_events)
      :ets.delete_all_objects(:prometheus_counter_table)
      :ets.delete_all_objects(:prometheus_histogram_table)
    end)
  end
end
