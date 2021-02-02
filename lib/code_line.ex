defmodule Covershow.CodeLine do
  @moduledoc """
  Data object for a line of code
  """

  defstruct [:value, :kind, :old_number, :new_number, :coverage]
end
