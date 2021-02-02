defmodule Covershow.Change do
  @moduledoc """
  Data object for change block
  """

  defstruct lines: [],
            new_start_line: 0,
            new_amount_lines: 0,
            old_start_line: 0,
            old_amount_lines: 0,
            old_filename: nil,
            new_filename: nil
end
