defmodule Covershow.Change do
  @moduledoc """
  Data object for change block
  """

  defstruct lines: [],
            new_start_line: 0,
            new_amount: 0,
            old_start_line: 0,
            old_amount: 0,
            old_filename: nil,
            new_filename: nil,
            lines_added: 0,
            lines_covered: 0,
            lines_missed: 0
end
