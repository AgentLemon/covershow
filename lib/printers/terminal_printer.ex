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
  @uncovered_line_number "#{ANSI.color_background(4, 3, 3)}#{ANSI.color(232)}"
  @covered_line_number "#{ANSI.color_background(3, 4, 3)}#{ANSI.color(232)}"
  @separator ANSI.color(246)
  @summary ANSI.bright()

  def print(files) do
    line_number_digits = get_line_number_max_digits(files)
    line_length = get_line_max_length(files)

    files
    |> Enum.each(fn file ->
      print_filename(file.new_filename, line_number_digits)
      print_stats(file, line_number_digits)

      file.blocks
      |> Enum.each(fn block ->
        print_code(block.lines, line_number_digits, line_length)
        "\n\n" |> IO.write()
      end)
    end)

    print_summary(files, line_number_digits, line_length)
  end

  defp get_line_max_length(files) do
    files
    |> Enum.flat_map(fn file ->
      file.blocks
      |> Enum.flat_map(fn change ->
        change.lines
        |> Enum.map(&String.length(&1.value))
      end)
    end)
    |> Enum.max(fn -> 0 end)
  end

  defp get_line_number_max_digits(files) do
    files
    |> Enum.flat_map(fn file ->
      file.blocks
      |> Enum.flat_map(fn block ->
        block.lines
        |> Enum.map(& &1.new_number)
        |> Enum.reject(&is_nil/1)
      end)
    end)
    |> Enum.max(fn -> 0 end)
    |> Integer.digits()
    |> Enum.count()
  end

  defp print_filename(filename, line_number_digits) do
    arrows = get_chars(line_number_digits, ">")

    "\n#{@filename}#{arrows} #{filename}#{@reset}\n"
    |> IO.write()
  end

  defp print_stats(change, line_number_digits) do
    spaces = get_chars(line_number_digits, " ")

    "#{spaces} lines added: #{change.added}    covered: #{change.covered}    missed: #{
      change.missed
    }\n\n"
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

  defp print_summary(files, line_number_digits, line_length) do
    {added, covered, missed} =
      files
      |> Enum.reduce({0, 0, 0}, fn change, {added, covered, missed} ->
        {added + change.added, covered + change.covered, missed + change.missed}
      end)

    coverage =
      if covered + missed > 0 do
        (100 * covered / (covered + missed)) |> Float.round(1)
      end

    separator = get_chars(line_number_digits + line_length + 1, "-")
    gap = get_chars(line_number_digits, " ")

    "#{@separator}#{separator}#{@reset}\n\n"
    |> IO.write()

    "#{gap} #{@summary}lines added:   #{added}#{@reset}\n" |> IO.write()
    "#{gap} #{@summary}lines covered: #{covered}#{@reset}\n" |> IO.write()
    "#{gap} #{@summary}lines missed:  #{missed}#{@reset}\n" |> IO.write()
    "#{gap} #{@summary}diff coverage: #{coverage}%#{@reset}\n" |> IO.write()
    "\n\n" |> IO.write()
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
