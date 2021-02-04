defmodule Covershow.Parsers.GitParser do
  @moduledoc """
  Functions to parse git diff
  """

  alias Covershow.Data.{Block, File, Line}

  def parse(lines) do
    file_list =
      lines
      |> Enum.reduce([], fn line, acc ->
        {file, rest} = shift(acc)

        case parse_line(line) do
          :diff ->
            [%File{} | acc]

          {:filename, kind, filename} ->
            file = Map.put(file, kind, filename)
            [file | rest]

          {:line_num, old_number, old_amount, new_number, new_amount} ->
            block = %Block{
              old_start_line: old_number,
              old_amount: old_amount,
              new_start_line: new_number,
              new_amount: new_amount
            }

            file = Map.put(file, :blocks, [block | file.blocks])
            [file | rest]

          {:code_line, kind, line} ->
            {block, rest_blocks} = shift(file.blocks)
            block = put_line(block, kind, line)
            file = Map.put(file, :blocks, [block | rest_blocks])
            [file | rest]

          nil ->
            acc
        end
      end)

    finish(file_list)
  end

  defp put_line(block, kind, line) do
    code_line = %Line{value: line, kind: kind}
    new_lines = [code_line | block.lines]
    Map.put(block, :lines, new_lines)
  end

  defp finish(file_list) do
    file_list
    |> Enum.map(fn file ->
      blocks = finish_blocks(file.blocks)
      Map.put(file, :blocks, blocks)
    end)
    |> Enum.reverse()
  end

  defp finish_blocks(blocks) do
    blocks
    |> Enum.map(fn block ->
      assign_line_numbers(block)
    end)
    |> Enum.reverse()
  end

  defp assign_line_numbers(block) do
    old_end = block.old_start_line + block.old_amount - 1
    new_end = block.new_start_line + block.new_amount - 1

    {lines, _, _} =
      block.lines
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

    Map.put(block, :lines, lines)
  end

  defp shift([]), do: {nil, []}
  defp shift([cursor | rest]), do: {cursor, rest}

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
    case Regex.scan(~r/^(---|\+\+\+) (a|b)?\/(.*)$/, line) do
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
