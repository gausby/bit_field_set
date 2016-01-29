defmodule BitFieldSetBench do
  use Benchfella

  @empty <<0::size(8000)>>
  @half_full IO.iodata_to_binary(for _ <- 1..1000, do: 170)
  @full IO.iodata_to_binary(for _ <- 1..1000, do: 255)

  # all bits set to 0
  bench "empty-bitfield" do
    BitFieldSet.new!(@empty, 8000)
  end

  # every other bit set to 1
  bench "half-full-bitfield" do
    BitFieldSet.new!(@full, 8000)
  end

  # every bit set to 1
  bench "full-bitfield" do
    BitFieldSet.new!(@full, 8000)
  end
end
