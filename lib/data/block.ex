defmodule Covershow.Data.Block do
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
            added: 0,
            covered: 0,
            missed: 0
end
