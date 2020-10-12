defmodule TelemetricEvents.PrometheusTest do
  use ExUnit.Case
  alias TelemetricEvents.TestModule

  describe "__using__" do
    test "test module has a setup/0 function" do
      assert function_exported?(TestModule, :setup, 0)
    end

    test "test module has an observe/2 function" do
      assert function_exported?(TestModule, :observe, 2)
    end
  end

  describe "created functions: setup" do
  setup :ets_setup
    test "setup creates the proper entries in prometheus :ets table: :prometheus_counter_table." do
      assert Enum.sort(:ets.tab2list(:prometheus_counter_table)) == [
               {{:default, :mf, :received_message_count},
                {['sender'], 'Counts number of messages received separated on sender'}, [],
                :undefined, :undefined},
               {{:default, :mf, :sent_message_count},
                {['recipient'], 'Counts number of messages sent separated on recipient'}, [],
                :undefined, :undefined}
             ]
    end

    test "setup creates the proper entries in prometheus :ets table: :prometheus_histogram_table." do
      assert :ets.tab2list(:prometheus_histogram_table) == [
               {{:default, :mf, :received_response_duration_milliseconds},
                {['recipient'],
                 'Buckets the time a sent message takes to round-robin to the recipient'}, [],
                :milliseconds, [50, 100, 500, 1000, :infinity]}
             ]
    end
  end

  describe "created functions: observe" do
  setup :ets_setup
    test "observe messages:received updates the proper :ets table" do
      TestModule.observe([:example, :messages, :received], %{sender: "test"})

      assert :prometheus_counter.values(:default, :received_message_count) == [
               {[{'sender', "test"}], 1}
             ]

      TestModule.observe([:example, :messages, :received], %{sender: "test", inc: 2})

      assert :prometheus_counter.values(:default, :received_message_count) == [
               {[{'sender', "test"}], 3}
             ]
    end

    test "observe messages:sent updates the proper :ets table" do
      TestModule.observe([:example, :messages, :sent], %{recipient: "test"})

      assert :prometheus_counter.values(:default, :sent_message_count) == [
               {[{'recipient', "test"}], 1}
             ]

      TestModule.observe([:example, :messages, :sent], %{recipient: "test", inc: 2})

      assert :prometheus_counter.values(:default, :sent_message_count) == [
               {[{'recipient', "test"}], 3}
             ]
    end

    test "observe responses:received updates the proper :ets table" do
      TestModule.observe([:example, :responses, :received], %{recipient: "test", observe: 439})

      assert :prometheus_histogram.values(:default, :received_response_duration_milliseconds) ==
               [
                 {
                   [{'recipient', "test"}],
                   [{50, 1}, {100, 0}, {500, 0}, {1000, 0}, {:infinity, 0}],
                   4.39e-4
                 }
               ]
    end
  end

  defp ets_setup(_context) do
    TestModule.setup()
    on_exit(fn ->
      :ets.delete_all_objects(:prometheus_counter_table)
      :ets.delete_all_objects(:prometheus_histogram_table)
    end)
  end

end
