defmodule BitFieldSetEqc do
  use ExUnit.Case
  use EQC.ExUnit
  use Bitwise

  describe "initializing bit fields" do
    property "converting data to a bit field set and back should yield the same result" do
      forall input <- binary() do
        size = bit_size(input)
        result = input |> BitFieldSet.new!(size) |> BitFieldSet.to_binary()
        ensure(result == input)
      end
    end

    property "initializing bit fields with varying sizes" do
      forall {size, a} <- gen_random_set() do
        result = a |> BitFieldSet.new!(size) |> BitFieldSet.to_list()
        expected = a |> convert_to_map_set(size) |> MapSet.to_list()
        ensure(Enum.sort(expected) == result)
      end
    end

    property "collectable protocol" do
      forall {size, a} <- gen_random_set() do
        bit_field = BitFieldSet.new!(a, size)

        result =
          bit_field
          |> BitFieldSet.to_list()
          |> Enum.into(%BitFieldSet{size: size})

        ensure(result == bit_field)
      end
    end
  end

  property "put/2" do
    forall {size, numbers} <- gen_random_set_of_numbers() do
      bit_field = BitFieldSet.new!(size + 1)

      result =
        numbers
        |> Enum.reduce(bit_field, &BitFieldSet.put(&2, &1))
        |> BitFieldSet.to_list()

      ensure(Enum.dedup(numbers) == result)
    end
  end

  defp gen_random_set_of_numbers() do
    sized size do
      {size, orderedlist(choose(0, size))}
    end
  end

  property "delete/2" do
    forall {add, remove} <- {orderedlist(choose(0, 15)), orderedlist(choose(0, 15))} do
      expected =
        remove
        |> Enum.reduce(
          add,
          &Enum.reject(&2, fn
            ^&1 -> true
            _ -> false
          end)
        )
        |> Enum.dedup()

      bit_field = Enum.into(add, %BitFieldSet{size: 16})

      result =
        remove
        |> Enum.reduce(bit_field, &BitFieldSet.delete(&2, &1))
        |> BitFieldSet.to_list()

      ensure(expected == result)
    end
  end

  # todo, make sure some tests are guaranteed disjoined
  property "disjoint?/2" do
    forall {size, a, b} <- gen_two_random_sets_of_same_size() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected = MapSet.disjoint?(map_set_a, map_set_b)
      result = BitFieldSet.disjoint?(bit_field_a, bit_field_b)

      ensure(expected == result)
    end
  end

  property "difference/2" do
    forall {size, a, b} <- gen_two_random_sets_of_same_size() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected =
        MapSet.difference(map_set_a, map_set_b)
        |> MapSet.to_list()
        |> Enum.sort()

      result =
        BitFieldSet.difference(bit_field_a, bit_field_b)
        |> BitFieldSet.to_list()

      ensure(expected == result)
    end
  end

  property "intersection/2" do
    forall {size, a, b} <- gen_two_random_sets_of_same_size() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected =
        MapSet.intersection(map_set_a, map_set_b)
        |> MapSet.to_list()
        |> Enum.sort()

      result =
        BitFieldSet.intersection(bit_field_a, bit_field_b)
        |> BitFieldSet.to_list()

      ensure(expected == result)
    end
  end

  property "union/2" do
    forall {size, a, b} <- gen_two_random_sets_of_same_size() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected =
        MapSet.union(map_set_a, map_set_b)
        |> MapSet.to_list()
        |> Enum.sort()

      result =
        BitFieldSet.union(bit_field_a, bit_field_b)
        |> BitFieldSet.to_list()

      ensure(expected == result)
    end
  end

  property "equal?/2" do
    # todo, should generate two sets that are equal once in a while
    forall {size, a, b} <- gen_two_random_sets_of_same_size() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected = MapSet.equal?(map_set_a, map_set_b)
      result = BitFieldSet.equal?(bit_field_a, bit_field_b)

      ensure(expected == result)
    end
  end

  property "subset?/2" do
    forall {size, a, b} <- gen_maybe_subset() do
      bit_field_a = BitFieldSet.new!(a, size)
      bit_field_b = BitFieldSet.new!(b, size)

      map_set_a = convert_to_map_set(a, size)
      map_set_b = convert_to_map_set(b, size)

      expected = MapSet.subset?(map_set_a, map_set_b)
      result = BitFieldSet.subset?(bit_field_a, bit_field_b)

      ensure(expected == result)
    end
  end

  # todo figure out how to pick random bits from a bitstring
  defp gen_maybe_subset() do
    sized size do
      let set <- bitstring(size) do
        {size, set, bitstring(size)}
      end
    end
  end

  property "size/2" do
    forall {size, a} <- gen_random_set() do
      expected = a |> convert_to_map_set(size) |> MapSet.size()
      result = a |> BitFieldSet.new!(size) |> BitFieldSet.size()
      ensure(expected == result)
    end
  end

  property "member?/2" do
    forall {size, haystack, needle} <- gen_haystack_and_needle() do
      implies needle >= 0 do
        expected =
          haystack
          |> convert_to_map_set(size)
          |> MapSet.member?(needle)

        result =
          haystack
          |> BitFieldSet.new!(size)
          |> BitFieldSet.member?(needle)

        ensure(expected == result)
      end
    end
  end

  defp gen_haystack_and_needle() do
    sized size do
      let haystack <- bitstring(size) do
        let needle <- nat() do
          {size, haystack, needle}
        end
      end
    end
  end

  # =Generators =========================================================
  defp gen_random_set() do
    sized size do
      {size, bitstring(size)}
    end
  end

  defp gen_two_random_sets_of_same_size() do
    sized size do
      {size, bitstring(size), bitstring(size)}
    end
  end

  # =Helpers ============================================================
  defp convert_to_map_set(data, set_size) when is_bitstring(data) do
    data_size = bit_size(data)
    <<bit_field::big-size(data_size)>> = data
    convert_to_map_set(bit_field, set_size)
  end

  defp convert_to_map_set(data, bit_size) when is_number(data) do
    {_counter, acc} =
      data
      |> Integer.digits(2)
      |> Enum.reverse()
      |> Enum.reduce({bit_size - 1, []}, fn
        0, {counter, acc} ->
          {counter - 1, acc}

        1, {counter, acc} ->
          {counter - 1, [counter | acc]}
      end)

    Enum.into(acc, MapSet.new())
  end
end
