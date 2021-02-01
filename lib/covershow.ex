defmodule Covershow do
  def foo do
    diff =
      "./diff"
      |> File.stream!()
      |> GitParser.parse()
      |> IO.inspect()

    coverage =
      "./excoveralls.json"
      |> File.read!()
      |> String.replace("\n", "\\n")
      |> Jason.decode!()
      |> Map.get("source_files", [])
      |> Enum.map(fn item ->
        source = item["source"] |> String.split("\n")
        Map.put(item, "source", source)
      end)
      |> Enum.group_by(fn item -> item["name"] end)

    diff
    |> Enum.each(fn change ->
      filename = change |> Map.get(:new_filename, nil)
      start_line = change |> Map.get(:line_num, 1)
      amount = change |> Map.get(:amount, 0)
      end_line = start_line + amount

      with false <- is_nil(filename),
           [coverage_record] <- coverage[filename] do
        IO.puts("\n#{filename}\n")

        (start_line - 1..end_line)
        |> Enum.each(fn i ->
          cov_value = coverage_record |> Map.get("coverage", []) |> Enum.at(i)
          code_line = coverage_record |> Map.get("source", []) |> Enum.at(i)

          cov_meaning =
            case cov_value do
              nil -> " "
              0 -> "-"
              _any -> "+"
            end

          "#{cov_meaning} #{code_line}" |> IO.puts()
        end)

        IO.puts("\n")
      end
    end)
  end
end
