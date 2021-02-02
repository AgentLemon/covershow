defmodule Covershow.Printers.TerminalPrinter do
  @moduledoc """
  Prints list of changes to terminal
  """

  alias IO.ANSI

  @reset ANSI.reset()
  @filename ANSI.bright()
  @line_number "#{ANSI.color_background(254)}#{ANSI.color(246)}"
  @uncovered ANSI.color_background(5, 4, 4)
  @covered ANSI.color_background(4, 5, 4)
  @unchanged ANSI.color(246)
  @uncovered_line_number "#{@uncovered}#{ANSI.color(232)}"
  @covered_line_number "#{@covered}#{ANSI.color(232)}"

  def print(change_list) do
    line_number_digits = get_line_number_max_digits(change_list)
    line_length = get_line_max_length(change_list)

    change_list
    |> Enum.each(fn change ->
      print_filename(change.new_filename, line_number_digits)
      print_code(change.lines, line_number_digits, line_length)
    end)
  end

  defp get_line_max_length(change_list) do
    change_list
    |> Enum.flat_map(fn change ->
      change.lines
      |> Enum.map(&String.length(&1.value))
    end)
    |> Enum.max()
  end

  defp get_line_number_max_digits(change_list) do
    change_list
    |> Enum.flat_map(fn change ->
      change.lines
      |> Enum.map(& &1.new_number)
      |> Enum.reject(&is_nil/1)
    end)
    |> Enum.max()
    |> Integer.digits()
    |> Enum.count()
  end

  defp print_filename(filename, line_number_digits) do
    arrows = get_chars(line_number_digits, ">")

    "\n\n#{@filename}#{arrows} #{filename}#{@reset}\n\n"
    |> IO.write()
  end

  defp print_code(lines, line_number_digits, line_length) do
    lines
    |> Enum.each(fn line -> print_line(line, line_number_digits, line_length) end)
  end

  defp print_line(%{kind: :remove}, _, _) do
    nil
  end

  defp print_line(line, line_number_digits, line_length) do
    {num_color, color} =
      cond do
        line.kind == :noop -> {@line_number, @unchanged}
        is_nil(line.coverage) -> {@line_number, @reset}
        line.coverage == 0 -> {@uncovered_line_number, @uncovered}
        line.coverage > 0 -> {@covered_line_number, @covered}
      end

    if line.kind == :noop do
      @unchanged
    end

    number = get_number(line.new_number, line_number_digits)
    code_line = append_spaces(line.value, line_length)

    "#{num_color}#{number}#{@reset}#{color} #{code_line}#{@reset}\n"
    |> IO.write()
  end

  defp get_number(number, digits) do
    prepend_spaces("#{number}", digits)
  end

  defp prepend_spaces(str, len) do
    str_len = String.length(str)
    spaces = get_chars(len - str_len, " ")
    spaces <> str
  end

  defp append_spaces(str, len) do
    str_len = String.length(str)
    spaces = get_chars(len - str_len, " ")
    str <> spaces
  end

  defp get_chars(amount, char) do
    if amount > 0 do
      1..amount |> Enum.reduce("", fn _, acc -> acc <> char end)
    else
      ""
    end
  end
end
