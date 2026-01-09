defmodule KernelX do

  @doc "Returns all bytes from `binary`, excluding those before `from`"
  @spec binary_slice_from(binary(), pos_integer()) :: binary()
  def binary_slice_from(binary, from) do
    binary_part(binary, from, byte_size(binary) - from)
  end
end
