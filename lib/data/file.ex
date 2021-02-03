defmodule Covershow.Data.File do
  @moduledoc """
  Data object for change block
  """

  defstruct blocks: [],
            old_filename: nil,
            new_filename: nil,
            added: 0,
            covered: 0,
            missed: 0
end
