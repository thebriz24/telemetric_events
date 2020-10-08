defmodule TelemetricEventsTest do
  use ExUnit.Case
  doctest TelemetricEvents

  test "greets the world" do
    assert TelemetricEvents.hello() == :world
  end
end
