defmodule TelemetricEvents.Logger.Test do
  use ExUnit.Case
  alias __MODULE__.TestStruct
  import ExUnit.CaptureLog
  require Logger

  describe "Logging" do
    setup do
      TelemetricEvents.setup_json_logging()

      on_exit(fn ->
        TelemetricEvents.restore_regular_logging()
      end)
    end

    test "when message is an atom map" do
      assert capture_log(fn -> Logger.info(%{test: "test"}) end) =~
               ~r/{"level":"info","test":"test","timestamp":".{19}"}/

      assert capture_log(fn -> Logger.info(%{test: :test}) end) =~
               ~r/{"level":"info","test":"test","timestamp":".{19}"}/
    end

    test "when message is an string map" do
      assert capture_log(fn -> Logger.info(%{"test" => "test"}) end) =~
               ~r/{"level":"info","test":"test","timestamp":".{19}"}/
    end

    test "when message is a map with non-standard keys" do
      assert capture_log(fn -> Logger.info(%{["actually", "works"] => "test"}) end) =~
               ~r/{"actuallyworks":"test","level":"info","timestamp":".{19}"}/
    end

    test "when message is a struct" do
      assert capture_log(fn -> Logger.info(%TestStruct{}) end) =~
               ~r/{"level":"info","test":"test","timestamp":".{19}"}/
    end

    test "when message is a keyword list" do
      assert capture_log(fn -> Logger.info(test: "test") end) =~
               ~r/{"level":"info","test":"test","timestamp":".{19}"}/
    end

    test "when messasge is a list" do
      assert capture_log(fn -> Logger.info(["test", 65]) end) =~
               ~r/{"message":"testA","level":"info","timestamp":".{19}"}/
    end

    test "when messasge is a charlist" do
      assert capture_log(fn -> Logger.info('test') end) =~
               ~r/{"message":"test","level":"info","timestamp":".{19}"}/
    end

    test "when messasge is a tuple" do
      assert_raise Protocol.UndefinedError, fn -> Logger.info({"test"}) end
    end

    test "when message is a string" do
      assert capture_log(fn -> Logger.info("test") end) =~
               ~r/{"message":"test","level":"info","timestamp":".{19}"}/
    end

    test "when message is an atom" do
      assert capture_log(fn -> Logger.info(:test) end) =~
               ~r/{"message":"test","level":"info","timestamp":".{19}"}/
    end

    test "when message is an integer" do
      assert capture_log(fn -> Logger.info(1) end) =~
               ~r/{"message":1,"level":"info","timestamp":".{19}"}/
    end

    test "when messasge is a float" do
      assert capture_log(fn -> Logger.info(1.0) end) =~
               ~r/{"message":1.0,"level":"info","timestamp":".{19}"}/
    end

    test "when message is nil" do
      assert capture_log(fn -> Logger.info(nil) end) =~
               ~r/{"message":null,"level":"info","timestamp":".{19}"}/
    end
  end
end
