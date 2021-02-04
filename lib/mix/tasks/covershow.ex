defmodule Mix.Tasks.Covershow do
  @moduledoc """
  Task to run covershow
  """

  use Mix.Task

  def run([commit]) do
    Covershow.print_coverage(commit)
  end

  def run(_) do
    "\n  Please use syntax:\n\n    mix covershow <commit_id | branch_name>\n\n"
    |> IO.write()
  end
end
