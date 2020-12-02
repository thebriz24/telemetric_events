defmodule TelemetricEvents.Logger.JSONBackend.Test do
  use ExUnit.Case

  alias TelemetricEvents.Logger.JSONBackend

  require Logger
  import ExUnit.CaptureIO

  setup do
    Logger.add_backend(JSONBackend)
    Logger.remove_backend(:console)

    on_exit(fn ->
      :ok =
        Logger.configure_backend(
          JSONBackend,
          device: :user,
          level: nil,
          metadata: [],
          colors: [enabled: false]
        )

      Logger.add_backend(:console)
      Logger.remove_backend(JSONBackend)
    end)
  end

  test "does not start when there is no user" do
    :ok = Logger.remove_backend(JSONBackend)
    user = Process.whereis(:user)

    try do
      Process.unregister(:user)

      assert :gen_event.add_handler(Logger, JSONBackend, JSONBackend) ==
               {:error, :ignore}
    after
      Process.register(user, :user)
    end
  after
    {:ok, _} = Logger.add_backend(JSONBackend)
  end

  test "may use another device" do
    Logger.configure_backend(JSONBackend, device: :standard_error)

    assert capture_io(:standard_error, fn ->
             Logger.debug("hello")
             Logger.flush()
           end) =~ "hello"
  end

  test "configures metadata" do
    Logger.configure_backend(JSONBackend, metadata: [:user_id])

    assert capture_log(fn -> Logger.debug("hello") end) =~
             ~r/\{"message":"hello","level":"debug","timestamp":".{19}"\}/

    Logger.metadata(user_id: 11)
    Logger.metadata(user_id: 13)

    assert capture_log(fn -> Logger.debug("hello") end) =~
             ~r/\{"message":"hello","user_id":13,"level":"debug","timestamp":".{19}"\}/
  end

  test "logs initial_call as metadata" do
    Logger.configure_backend(JSONBackend, metadata: [:initial_call])

    assert capture_log(fn -> Logger.debug("hello", initial_call: {Foo, :bar, 3}) end) =~
             ~r/\{"initial_call":"Elixir\.Foo\.bar\/3","message":"hello","level":"debug","timestamp":".{19}"\}/
  end

  test "logs domain as metadata" do
    Logger.configure_backend(JSONBackend, metadata: [:domain])

    assert capture_log(fn -> Logger.debug("hello", domain: [:foobar]) end) =~
             ~r/\{"domain":\["elixir","foobar"\],"message":"hello","level":"debug","timestamp":".{19}"\}/
  end

  test "logs mfa as metadata" do
    Logger.configure_backend(JSONBackend, metadata: [:mfa])

    log = capture_log(fn -> Logger.debug("hello") end)

    assert log =~
             ~r/"mfa":"Elixir\.TelemetricEvents\.Logger\.JSONBackend\.Test\.test logs mfa as metadata\/1"/

    assert log =~ ~r/"message":"hello"/
    assert log =~ ~r/"level":"debug"/
    assert log =~ ~r/"timestamp":".{19}"\}/
  end

  test "ignores crash_reason metadata when configured with metadata: :all" do
    Logger.configure_backend(JSONBackend, metadata: :all)
    Logger.metadata(crash_reason: {%RuntimeError{message: "oops"}, []})
    log = capture_log(fn -> Logger.debug("hello") end)
    assert log =~ ~r/"message":"hello"/
    assert log =~ ~r/"level":"debug"/
    assert log =~ ~r/"timestamp":".{19}"\}/
    assert log =~ ~r/"crash_reason":"%RuntimeError\{message: \\"oops\\"\}"/
    assert log =~ ~r/"domain":\["elixir"\]/
    assert log =~ ~r/"erl_level":"debug"/
  end

  test "configures metadata to :all" do
    Logger.configure_backend(JSONBackend, metadata: :all)
    Logger.metadata(user_id: 11)
    Logger.metadata(dynamic_metadata: 5)

    %{module: mod, function: {name, arity}, file: file, line: line} = __ENV__
    log = capture_log(fn -> Logger.debug("hello") end)

    assert log =~ ~r/"file":"#{file}"/
    assert log =~ ~r/"line":#{line + 1}/
    assert log =~ ~r/"module":"Elixir\.#{inspect(mod)}"/
    assert log =~ ~r/"function":"#{name}\/#{arity}"/
    assert log =~ ~r/"dynamic_metadata":5/
    assert log =~ ~r/"user_id":11/
  end

  test "provides metadata defaults" do
    metadata = [:file, :line, :module, :function]
    Logger.configure_backend(JSONBackend, metadata: metadata)

    %{module: mod, function: {name, arity}, file: file, line: line} = __ENV__
    log = capture_log(fn -> Logger.debug("hello") end)

    assert log =~ ~r/"file":"#{file}"/
    assert log =~ ~r/"line":#{line + 1}/
    assert log =~ ~r/"module":"Elixir\.#{inspect(mod)}"/
    assert log =~ ~r/"function":"#{name}\/#{arity}"/
  end

  test "configures level" do
    Logger.configure_backend(JSONBackend, level: :info)

    assert capture_log(fn -> Logger.debug("hello") end) == ""
  end

  test "configures colors" do
    Logger.configure_backend(JSONBackend, colors: [enabled: true])

    result = capture_log(fn -> Logger.debug("hello") end)
    check_color(result, IO.ANSI.cyan())

    Logger.configure_backend(JSONBackend, colors: [debug: :magenta])

    result = capture_log(fn -> Logger.debug("hello") end)
    check_color(result, IO.ANSI.magenta())

    result = capture_log(fn -> Logger.info("hello") end)
    check_color(result, IO.ANSI.normal())

    Logger.configure_backend(JSONBackend, colors: [info: :cyan])

    result = capture_log(fn -> Logger.info("hello") end)
    check_color(result, IO.ANSI.cyan())

    result = capture_log(fn -> Logger.warn("hello") end)
    check_color(result, IO.ANSI.yellow())

    Logger.configure_backend(JSONBackend, colors: [warn: :cyan])

    result = capture_log(fn -> Logger.warn("hello") end)
    check_color(result, IO.ANSI.cyan())

    result = capture_log(fn -> Logger.error("hello") end)
    check_color(result, IO.ANSI.red())

    Logger.configure_backend(JSONBackend, colors: [error: :cyan])

    result = capture_log(fn -> Logger.error("hello") end)
    check_color(result, IO.ANSI.cyan())
  end

  test "uses colors from metadata" do
    Logger.configure_backend(JSONBackend, colors: [enabled: true])

    result = capture_log(fn -> Logger.log(:error, "hello", ansi_color: :yellow) end)
    assert String.starts_with?(result, IO.ANSI.yellow())
    assert String.ends_with?(result, IO.ANSI.reset())
  end

  def capture_log(level \\ :debug, fun) do
    current = Logger.level()
    Logger.configure(level: level)

    try do
      capture_io(:user, fn ->
        fun.()
        Logger.flush()
      end)
    after
      Logger.configure(level: current)
    end
  end

  defp check_color(result, color) do
    assert String.starts_with?(result, color)
    assert String.ends_with?(result, IO.ANSI.reset())
  end
end
