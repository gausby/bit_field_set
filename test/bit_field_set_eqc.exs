defmodule BitFieldSetEqc do
  use ExUnit.Case
  use EQC.ExUnit

  property "converting data to a bit field set and back should yield the same result" do
    forall input <- binary(1000) do
      result = BitFieldSet.new!(input, 8000) |> BitFieldSet.to_binary
      ensure result == input
    end
  end

  property "collectable protocol" do
    forall input <- binary(1000) do
      bit_field = BitFieldSet.new!(input, 8000)

      result =
        bit_field
        |> BitFieldSet.to_list()
        |> Enum.into(%BitFieldSet{size: 8000})

      ensure result == bit_field
    end
  end

  # describe "put/2" do ... end
  # describe "delete/2" do ... end

  describe "disjoint?/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected =
          MapSet.disjoint?(map_set_a, map_set_b)

        result =
          BitFieldSet.disjoint?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected =
          MapSet.disjoint?(map_set_a, map_set_b)

        result =
          BitFieldSet.disjoint?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end
  end

  describe "difference/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected =
          MapSet.difference(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.difference(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected =
          MapSet.difference(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.difference(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end
  end

  describe "intersection/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected =
          MapSet.intersection(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.intersection(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected =
          MapSet.intersection(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.intersection(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end
  end

  describe "union/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected =
          MapSet.union(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.union(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected =
          MapSet.union(map_set_a, map_set_b)
          |> MapSet.to_list()
          |> Enum.sort()

        result =
          BitFieldSet.union(bit_field_a, bit_field_b)
          |> BitFieldSet.to_list()

        ensure expected == result
      end
    end
  end

  describe "equal?/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected = MapSet.equal?(map_set_a, map_set_b)
        result = BitFieldSet.equal?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected = MapSet.equal?(map_set_a, map_set_b)
        result = BitFieldSet.equal?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end
  end

  describe "subset?/2" do
    property "small set" do
      forall {a, b} <- {binary(2), binary(2)} do
        bit_field_a = BitFieldSet.new!(a, 16)
        bit_field_b = BitFieldSet.new!(b, 16)

        map_set_a = convert_binary_to_map_set(a, 16)
        map_set_b = convert_binary_to_map_set(b, 16)

        expected = MapSet.subset?(map_set_a, map_set_b)
        result = BitFieldSet.subset?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end

    property "large set" do
      forall {a, b} <- {binary(1000), binary(1000)} do
        bit_field_a = BitFieldSet.new!(a, 8000)
        bit_field_b = BitFieldSet.new!(b, 8000)

        map_set_a = convert_binary_to_map_set(a, 8000)
        map_set_b = convert_binary_to_map_set(b, 8000)

        expected = MapSet.subset?(map_set_a, map_set_b)
        result = BitFieldSet.subset?(bit_field_a, bit_field_b)

        ensure expected == result
      end
    end
  end

  describe "size/2" do
    property "small set" do
      forall a <- binary(2) do
        bit_field = BitFieldSet.new!(a, 16)
        map_set = convert_binary_to_map_set(a, 16)

        expected = MapSet.size(map_set)
        result = BitFieldSet.size(bit_field)

        ensure expected == result
      end
    end

    property "large set" do
      forall a <- binary(1000) do
        bit_field = BitFieldSet.new!(a, 8000)
        map_set = convert_binary_to_map_set(a, 8000)

        expected = MapSet.size(map_set)
        result = BitFieldSet.size(bit_field)

        ensure expected == result
      end
    end
  end

  describe "member?/2" do
    property "small set" do
      forall {haystack, needle} <- {binary(2), choose(0, 15)} do
        bit_field = BitFieldSet.new!(haystack, 16)
        map_set = convert_binary_to_map_set(haystack, 16)

        expected = MapSet.member?(map_set, needle)
        result = BitFieldSet.member?(bit_field, needle)

        ensure expected == result
      end
    end

    property "large set" do
      forall {haystack, needle} <- {binary(1000), choose(0, 7999)} do
        bit_field = BitFieldSet.new!(haystack, 8000)
        map_set = convert_binary_to_map_set(haystack, 8000)

        expected = MapSet.member?(map_set, needle)
        result = BitFieldSet.member?(bit_field, needle)

        ensure expected == result
      end
    end
  end

  defp convert_binary_to_map_set(data, bit_size) do
    data_size = byte_size(data) * 8
    <<bit_field::big-size(data_size)>> = data

    {_counter, acc} =
      bit_field
      |> Integer.digits(2)
      |> Enum.reverse()
      |> Enum.reduce({bit_size - 1, []}, fn
           (0, {counter, acc}) ->
             {counter - 1, acc}

           (1, {counter, acc}) ->
             {counter - 1, [counter|acc]}
         end)

    Enum.into(acc, MapSet.new())
  end
end
