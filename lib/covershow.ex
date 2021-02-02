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
        {added, covered, missed} = get_stats(new_lines)

        new_change =
          change
          |> Map.merge(%{
            lines: new_lines,
            lines_added: added,
            lines_covered: covered,
            lines_missed: missed
          })

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

  defp get_stats(lines) do
    lines
    |> Enum.reduce({0, 0, 0}, fn line, {added, covered, missed} ->
      new_added =
        if line.kind == :add do
          added + 1
        else
          added
        end

      case line.coverage do
        nil -> {new_added, covered, missed}
        0 -> {new_added, covered, missed + 1}
        _ -> {new_added, covered + 1, missed}
      end
    end)
  end
end
