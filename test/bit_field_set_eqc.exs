defmodule BitFieldSetEqc do
  use ExUnit.Case
  use EQC.ExUnit

  property "converting data to a bit field set and back should yield the same" do
    forall input <- binary(1000) do
      result = input |> BitFieldSet.new!(8000) |> BitFieldSet.to_binary
      ensure result == input
    end
  end

  property "subsets" do
    forall {a, b, c} <- {binary(10), binary(10), binary(10)} do
      implies b != <<0::size(80)>> do
        {:ok, set_a} = BitFieldSet.new(a <> b <> c, 240)
        {:ok, set_b} = BitFieldSet.new(<<0::size(80)>> <> b <> <<0::size(80)>>, 240)

        ensure BitFieldSet.subset?(set_b, set_a) == true
      end
    end
  end

  property "equal" do
    forall {a, b} <- {binary(100), binary(100)} do
      implies a != b do
        {:ok, set_a} = BitFieldSet.new(a, 800)
        {:ok, set_b} = BitFieldSet.new(b, 800)

        ensure BitFieldSet.equal?(set_a, set_b) == false
      end
    end
  end

  property "union" do
    forall {a, b} <- {binary(10), binary(10)} do
      implies a != b do
        empty = <<0::size(80)>>
        {:ok, set_a} = BitFieldSet.new(a <> empty, 160)
        {:ok, set_b} = BitFieldSet.new(empty <> b, 160)
        result =
          BitFieldSet.new!(a <> b, 160)
          |> BitFieldSet.to_list

        ensure Enum.sort(MapSet.to_list(BitFieldSet.union(set_a, set_b))) == result
      end
    end
  end

  property "intersection" do
    forall {a, b, c} <- {binary(10), binary(10), binary(10)} do
      implies a != b do
        empty = <<0::size(80)>>
        {:ok, set_a} = BitFieldSet.new(a <> empty <> c, 240)
        {:ok, set_b} = BitFieldSet.new(empty <> b <> c, 240)
        result =
          BitFieldSet.new!(empty <> empty <> c, 240)
          |> BitFieldSet.to_list

        ensure Enum.sort(MapSet.to_list(BitFieldSet.intersection(set_a, set_b))) == result
      end
    end
  end

  property "a disjoint set should be disjoint" do
    forall {a, b, c, d} <- {binary(10), binary(10), binary(10), binary(10)} do
      implies a != b && c != d do
        empty = <<0::size(80)>>
        {:ok, set_a} = BitFieldSet.new(a <> empty <> c <> empty, 320)
        {:ok, set_b} = BitFieldSet.new(empty <> b <> empty <> d, 320)

        ensure BitFieldSet.disjoint?(set_a, set_b) == true
      end
    end
  end

  property "two non-disjoint set should not be disjoint" do
    forall {a, b, c, d} <- {binary(10), binary(10), binary(10), binary(10)} do
      implies a != b && c != d do
        empty = <<0::size(80)>>
        {:ok, set_a} = BitFieldSet.new(a <> b <> c <> empty, 320)
        {:ok, set_b} = BitFieldSet.new(empty <> b <> empty <> d, 320)

        ensure BitFieldSet.disjoint?(set_a, set_b) == false
      end
    end
  end
end
