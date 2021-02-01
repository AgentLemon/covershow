defmodule GitParser do
  def parse(lines) do
    result =
      lines
      |> Enum.reduce([%{}], fn line, acc ->
        [cursor | rest] = acc

        case parse_line(line) do
          :diff ->
            lines = cursor |> Map.get(:lines, []) |> Enum.reverse()
            cursor = Map.put(cursor, :lines, lines)
            [%{} | [cursor | rest]]

          {:line_num, number, amount} ->
            cursor = cursor |> Map.merge(%{line_num: number, amount: amount})
            [cursor | rest]

          {:filename, kind, filename} ->
            cursor = Map.put(cursor, kind, filename)
            [cursor | rest]

          {:code_line, kind, code_line} ->
            lines = Map.get(cursor, :lines, [])
            lines = [{kind, code_line} | lines]
            cursor = Map.put(cursor, :lines, lines)
            [cursor | rest]

          nil ->
            acc
        end
      end)

    result
    |> Enum.reverse()
  end

  defp parse_line(line) do
    check_diff(line) ||
      check_filename(line) ||
      check_line_nums(line) ||
      check_code_line(line)
  end

  defp check_diff(line) do
    case Regex.scan(~r/^diff/, line) do
      [] -> nil
      [[_]] -> :diff
    end
  end

  defp check_filename(line) do
    case Regex.scan(~r/^(---|\+\+\+) (a|b)\/(.*)$/, line) do
      [] -> nil
      [[_, "---", _, filename]] -> {:filename, :old_filename, filename}
      [[_, "+++", _, filename]] -> {:filename, :new_filename, filename}
    end
  end

  defp check_line_nums(line) do
    case Regex.scan(~r/^@@ -[0-9]+,[0-9]+ \+([0-9]+),([0-9]+) @@/, line) do
      [] -> nil
      [[_, line_num, amount]] -> {:line_num, parse_int(line_num), parse_int(amount)}
    end
  end

  defp check_code_line(line) do
    case Regex.scan(~r/^(\+|-| )(.*)$/, line) do
      [] -> nil
      [[_, "+", code_line]] -> {:code_line, :add, code_line}
      [[_, "-", code_line]] -> {:code_line, :remove, code_line}
      [[_, " ", code_line]] -> {:code_line, :nup, code_line}
    end
  end

  defp parse_int(string) do
    {int, _} = Integer.parse(string)
    int
  end
end
