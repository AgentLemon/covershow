defmodule CovershowTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest Covershow

  test "greets the world" do
    capture_log(fn ->
      assert Covershow.foo("HEAD") == :ok
    end)
  end
end
