defmodule BitFieldSetEqc do
  use ExUnit.Case
  use EQC.ExUnit

  property "subsets" do
    forall {a, b, c} <- {binary(10), binary(10), binary(10)} do
      implies b != <<0::size(80)>> do
        set_a = BitFieldSet.new(a <> b <> c)
        set_b = BitFieldSet.new(<<0::size(80)>> <> b <> <<0::size(80)>>)

        ensure BitFieldSet.subset?(set_b, set_a) == true
      end
    end
  end

  property "equal" do
    forall {a, b} <- {binary(100), binary(100)} do
      implies a != b do
        set_a = BitFieldSet.new(a)
        set_b = BitFieldSet.new(b)

        ensure BitFieldSet.equal?(set_a, set_b) == false
      end
    end
  end

  property "union" do
    forall {a, b} <- {binary(10), binary(10)} do
      implies a != b do
        empty = <<0::size(80)>>
        set_a = BitFieldSet.new(a <> empty)
        set_b = BitFieldSet.new(empty <> b)
        result =
          BitFieldSet.new(a <> b)
          |> BitFieldSet.to_list

        ensure MapSet.to_list(BitFieldSet.union(set_a, set_b)) == result
      end
    end
  end

  property "intersection" do
    forall {a, b, c} <- {binary(10), binary(10), binary(10)} do
      implies a != b do
        empty = <<0::size(80)>>
        set_a = BitFieldSet.new(a <> empty <> c)
        set_b = BitFieldSet.new(empty <> b <> c)
        result =
          BitFieldSet.new(empty <> empty <> c)
          |> BitFieldSet.to_list

        ensure MapSet.to_list(BitFieldSet.intersection(set_a, set_b)) == result
      end
    end
  end

  property "a disjoint set should be disjoint" do
    forall {a, b, c, d} <- {binary(10), binary(10), binary(10), binary(10)} do
      implies a != b && c != d do
        empty = <<0::size(80)>>
        set_a = BitFieldSet.new(a <> empty <> c <> empty)
        set_b = BitFieldSet.new(empty <> b <> empty <> d)

        ensure BitFieldSet.disjoint?(set_a, set_b) == true
      end
    end
  end

  property "two non-disjoint set should not be disjoint" do
    forall {a, b, c, d} <- {binary(10), binary(10), binary(10), binary(10)} do
      implies a != b && c != d do
        empty = <<0::size(80)>>
        set_a = BitFieldSet.new(a <> b <> c <> empty)
        set_b = BitFieldSet.new(empty <> b <> empty <> d)

        ensure BitFieldSet.disjoint?(set_a, set_b) == false
      end
    end
  end
end
