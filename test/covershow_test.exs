defmodule CovershowTest do
  use ExUnit.Case
  doctest Covershow

  test "greets the world" do
    assert Covershow.hello() == :world
  end
end
