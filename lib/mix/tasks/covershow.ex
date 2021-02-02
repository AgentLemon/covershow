defmodule Mix.Tasks.Covershow do
  use Mix.Task

  def run([commit]) do
    Covershow.foo(commit)
  end
end
