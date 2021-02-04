defmodule CovershowTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Mock
  doctest Covershow

  describe "does it's job" do
    setup do
      diff = "./fixtures/diff" |> Path.expand(__DIR__) |> File.read!()
      coverage = "./fixtures/coverage.json" |> Path.expand(__DIR__) |> File.read!()

      %{diff: diff, coverage: coverage}
    end

    test "greets the world", %{diff: diff, coverage: coverage} do
      with_mock(System, cmd: fn _, _ -> {diff, 0} end) do
        with_mock(File, read!: fn _ -> coverage end) do
          log =
            capture_io(fn ->
              Mix.Tasks.Covershow.run(["HEAD"])
            end)

          covered_style = IO.ANSI.color_background(4, 5, 4) |> String.replace("[", "\\[")
          uncovered_style = IO.ANSI.color_background(5, 4, 4) |> String.replace("[", "\\[")

          assert log =~ ~r/lib\/foobar1.ex/
          assert log =~ ~r/lib\/foobar2.ex/
          refute log =~ ~r/lib\/foobar3.ex/
          assert log =~ ~r/22.*covered added line 1/
          assert log =~ ~r/#{covered_style}.*covered/
          assert log =~ ~r/#{uncovered_style}.*uncovered/
        end
      end
    end
  end
end
