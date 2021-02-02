defmodule Covershow do
  alias Covershow.Printers.TerminalPrinter

  def foo(commit) do
    {raw_diff, 0} = System.cmd("git", ["diff", commit])

    diff =
      raw_diff
      |> String.split("\n")
      |> Covershow.GitParser.parse()

    coverage =
      "./cover/excoveralls.json"
      |> File.read!()
      |> String.replace("\n", "\\n")
      |> Jason.decode!()
      |> Map.get("source_files", [])
      |> Enum.group_by(fn item -> item["name"] end)

    diff
    |> Enum.reduce([], fn change, acc ->
      with [coverage_record] <- coverage[change.new_filename] do
        new_lines = change.lines |> assign_coverage(coverage_record)
        new_change = change |> Map.put(:lines, new_lines)
        [new_change | acc]
      else
        _any -> acc
      end
    end)
    |> Enum.reverse()
    |> TerminalPrinter.print()
  end

  def foobar do
    a = "ololo"
    b = a <> "lolo"
    nil
  end

  defp assign_coverage(lines, coverage_record) do
    lines
    |> Enum.map(fn line ->
      if line.kind == :remove do
        line
      else
        coverage = coverage_record |> Map.get("coverage", []) |> Enum.at(line.new_number - 1)
        line |> Map.put(:coverage, coverage)
      end
    end)
  end
end
