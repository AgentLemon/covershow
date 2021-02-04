defmodule Covershow do
  @moduledoc """
  Logic to get all data and send it to printer
  """

  alias Covershow.Parsers.GitParser
  alias Covershow.Printers.TerminalPrinter

  def print_coverage(commit) do
    diff = get_diff(commit)
    coverage = get_coverage()

    diff
    |> Enum.map(fn file ->
      with [coverage_record] <- coverage[file.new_filename] do
        blocks = process_blocks(file.blocks, coverage_record)
        {added, covered, missed} = summarise_stats(blocks)
        file |> Map.merge(%{blocks: blocks, added: added, covered: covered, missed: missed})
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> TerminalPrinter.print()
  end

  defp get_diff(commit) do
    {raw_diff, 0} = System.cmd("git", ["diff", commit])

    raw_diff
    |> String.split("\n")
    |> GitParser.parse()
  end

  defp get_coverage do
    "./cover/excoveralls.json"
    |> File.read!()
    |> String.replace("\n", "\\n")
    |> Jason.decode!()
    |> Map.get("source_files", [])
    |> Enum.group_by(fn item -> item["name"] end)
  end

  defp assign_coverage(lines, coverage_record) do
    lines
    |> Enum.map(fn line ->
      if line.kind == :remove do
        line
      else
        coverage = coverage_record |> Map.get("coverage", []) |> Enum.at(line.new_number - 1)
        Map.put(line, :coverage, coverage)
      end
    end)
  end

  defp process_blocks(blocks, coverage_record) do
    blocks
    |> Enum.map(fn block ->
      new_lines = block.lines |> assign_coverage(coverage_record)
      {added, covered, missed} = get_stats(new_lines)

      block
      |> Map.merge(%{
        lines: new_lines,
        added: added,
        covered: covered,
        missed: missed
      })
    end)
  end

  defp get_stats(lines) do
    lines
    |> Enum.reduce({0, 0, 0}, fn line, {added, covered, missed} ->
      if line.kind == :add do
        case line.coverage do
          nil -> {added + 1, covered, missed}
          0 -> {added + 1, covered, missed + 1}
          _ -> {added + 1, covered + 1, missed}
        end
      else
        {added, covered, missed}
      end
    end)
  end

  defp summarise_stats(blocks) do
    blocks
    |> Enum.reduce({0, 0, 0}, fn block, {added, covered, missed} ->
      {added + block.added, covered + block.covered, missed + block.missed}
    end)
  end
end
