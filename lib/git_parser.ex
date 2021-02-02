defmodule Covershow.GitParser do
  @moduledoc """
  Functions to parse git diff
  """

  alias Covershow.{Change, CodeLine}

  def parse(lines) do
    result =
      lines
      |> Enum.reduce([], fn line, acc ->
        {cursor, rest} = get_cursor(acc)

        case parse_line(line) do
          :diff ->
            changes = finish_change(cursor, rest)
            [%Change{} | changes]

          {:line_num, old_number, old_amount, new_number, new_amount} ->
            cursor =
              cursor
              |> Map.merge(%{
                old_start_line: old_number,
                old_amount: old_amount,
                new_start_line: new_number,
                new_amount: new_amount
              })

            [cursor | rest]

          {:filename, kind, filename} ->
            cursor = Map.put(cursor, kind, filename)
            [cursor | rest]

          {:code_line, kind, line} ->
            cursor = put_line(cursor, kind, line)
            [cursor | rest]

          nil ->
            acc
        end
      end)

    {cursor, rest} = get_cursor(result)

    cursor
    |> finish_change(rest)
    |> Enum.reverse()
  end

  defp put_line(cursor, kind, line) do
    code_line = %CodeLine{value: line, kind: kind}
    new_lines = [code_line | cursor.lines]
    Map.put(cursor, :lines, new_lines)
  end

  defp finish_change(nil, rest), do: rest

  defp finish_change(cursor, rest) do
    new_cursor = cursor |> assign_line_numbers()
    [new_cursor | rest]
  end

  defp assign_line_numbers(cursor) do
    old_end = cursor.old_start_line + cursor.old_amount - 1
    new_end = cursor.new_start_line + cursor.new_amount - 1

    {new_lines, _, _} =
      cursor.lines
      |> Enum.reduce(
        {[], old_end, new_end},
        fn line, {lines, old_counter, new_counter} ->
          case line.kind do
            :add ->
              new_line = line |> Map.put(:new_number, new_counter)
              {[new_line | lines], old_counter, new_counter - 1}

            :remove ->
              new_line = line |> Map.put(:old_number, old_counter)
              {[new_line | lines], old_counter - 1, new_counter}

            :noop ->
              new_line = line |> Map.merge(%{old_number: old_counter, new_number: new_counter})
              {[new_line | lines], old_counter - 1, new_counter - 1}
          end
        end
      )

    cursor |> Map.put(:lines, new_lines)
  end

  defp get_cursor([]), do: {nil, []}
  defp get_cursor([cursor | rest]), do: {cursor, rest}

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
    case Regex.scan(~r/^@@ -([0-9]+),([0-9]+) \+([0-9]+),([0-9]+) @@/, line) do
      [] ->
        nil

      [[_, old_line_num, old_amount, new_line_num, new_amount]] ->
        {:line_num, parse_int(old_line_num), parse_int(old_amount), parse_int(new_line_num),
         parse_int(new_amount)}
    end
  end

  defp check_code_line(line) do
    case Regex.scan(~r/^(\+|-| )(.*)$/, line) do
      [] -> nil
      [[_, "+", code_line]] -> {:code_line, :add, code_line}
      [[_, "-", code_line]] -> {:code_line, :remove, code_line}
      [[_, " ", code_line]] -> {:code_line, :noop, code_line}
    end
  end

  defp parse_int(string) do
    {int, _} = Integer.parse(string)
    int
  end
end
