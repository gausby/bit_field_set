defmodule BitFieldSetTest do
  use ExUnit.Case
  doctest BitFieldSet

  test "creating a new empty bitfield" do
    {:ok, bitfield} = BitFieldSet.new(32)
    expected = MapSet.new
    assert %BitFieldSet{size: 32, pieces: ^expected} = bitfield
  end

  test "creating a new bitfield with data" do
    {:ok, bitfield} = BitFieldSet.new(<<128, 64, 32, 48>>, 32)

    expected = MapSet.new([0, 9, 18, 26, 27])
    assert %BitFieldSet{size: 32, pieces: ^expected} = bitfield
  end

  test "bit fields should be able to hold sets of arbitrary sizes" do
    {:ok, bitfield} = BitFieldSet.new(<<128, 64, 32, 48, 128>>, 33)
    expected = MapSet.new([0, 9, 18, 26, 27, 32])
    assert %BitFieldSet{size: 33, pieces: ^expected} = bitfield
  end

  test "bit fields should throw an error if bits are out of bounds" do
    assert {:error, :out_of_bounds} = BitFieldSet.new(<<128, 64, 32, 48, 129>>, 33)
    assert {:error, :out_of_bounds} = BitFieldSet.new(<<0::size(120)>>, 33)
  end

  test "turning a bitfield into a binary" do
    result =
      BitFieldSet.new!(<<74, 0, 0>>, 24)
      |> BitFieldSet.to_binary
    expected = <<74, 0, 0>>
    assert result == expected

    result =
      BitFieldSet.new!(<<0, 74, 0>>, 24)
      |> BitFieldSet.to_binary
    expected = <<0, 74, 0>>
    assert result == expected

    result =
      BitFieldSet.new!(<<0, 0, 74>>, 24)
      |> BitFieldSet.to_binary
    expected = <<0, 0, 74>>
    assert result == expected

    result =
      BitFieldSet.new!(<<1, 255, 74>>, 24)
      |> BitFieldSet.to_binary
    expected = <<1, 255, 74>>
    assert result == expected
  end

  test "getting bits" do
    {:ok, bitfield} = BitFieldSet.new(<<128, 129, 255, 1>>, 32)

    assert BitFieldSet.member?(bitfield, 0) == true
    assert BitFieldSet.member?(bitfield, 1) == false
    assert BitFieldSet.member?(bitfield, 8) == true
    assert BitFieldSet.member?(bitfield, 14) == false
    assert BitFieldSet.member?(bitfield, 15) == true
    assert BitFieldSet.member?(bitfield, 16) == true

    assert BitFieldSet.member?(bitfield, 30) == false
    assert BitFieldSet.member?(bitfield, 31) == true
  end

  test "setting bits" do
    result =
      BitFieldSet.new!(16)
      |> BitFieldSet.set(2)
      |> BitFieldSet.set(4)
      |> BitFieldSet.set(6)
      |> BitFieldSet.set(8)
      |> BitFieldSet.set(15)

    expected = <<42, 129>>
    assert BitFieldSet.to_binary(result) == expected
  end

  test "setting all bits using set_all/1" do
    assert (BitFieldSet.new!(<<0b00000000>>, 8) |> BitFieldSet.set_all) == BitFieldSet.new!(<<255>>, 8)
    assert (BitFieldSet.new!(<<0b11100100>>, 8) |> BitFieldSet.set_all) == BitFieldSet.new!(<<255>>, 8)
    result = <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>
    assert (BitFieldSet.new!(120) |> BitFieldSet.set_all) == BitFieldSet.new!(result, 120)
  end

  test "removing bits" do
    bitfield =
      BitFieldSet.new!(8)
      |> BitFieldSet.set(2)
      |> BitFieldSet.remove(2)
    assert BitFieldSet.to_binary(bitfield) == <<0>>

    bitfield =
      BitFieldSet.new!(8)
      |> BitFieldSet.set(0)
      |> BitFieldSet.set(2)
      |> BitFieldSet.set(4)
      |> BitFieldSet.set(6) # 10101010
      |> BitFieldSet.remove(0) # 101010
    assert BitFieldSet.to_binary(bitfield) == <<42>>
  end

  test "counting the available pieces in a bitfield" do
    assert BitFieldSet.has(BitFieldSet.new!(<<255>>, 8)) == 8
    assert BitFieldSet.has(BitFieldSet.new!(<<170>>, 8)) == 4
    assert BitFieldSet.has(BitFieldSet.new!(<<42>>, 8)) == 3
    assert BitFieldSet.has(BitFieldSet.new!(<<10>>, 8)) == 2
    assert BitFieldSet.has(BitFieldSet.new!(<<1>>, 8)) == 1
    assert BitFieldSet.has(BitFieldSet.new!(<<0>>, 8)) == 0

    assert BitFieldSet.has(BitFieldSet.new!(<<1,1,1>>, 24)) == 3
    assert BitFieldSet.has(BitFieldSet.new!(<<10,10,10>>, 24)) == 6
    assert BitFieldSet.has(BitFieldSet.new!(<<170,170,170>>, 24)) == 12
  end

  test "has all" do
    assert BitFieldSet.has_all?(BitFieldSet.new!(<<255>>, 8)) == true
    assert BitFieldSet.has_all?(BitFieldSet.new!(<<254>>, 8)) == false
    assert BitFieldSet.has_all?(BitFieldSet.new!(<<255, 1>>, 16)) == false
    assert BitFieldSet.has_all?(BitFieldSet.new!(<<255, 255>>, 16)) == true
  end

  test "get available pieces for a bit-field as a list" do
    assert BitFieldSet.to_list(BitFieldSet.new!(<<128, 128>>, 16)) == [0, 8]
    assert BitFieldSet.to_list(BitFieldSet.new!(<<255, 255>>, 16)) == Enum.to_list(0..15)
  end

  test "intersection" do
    {:ok, bitfield1} = BitFieldSet.new(<<190, 106>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<106, 190>>, 16)

    expected = MapSet.new([2, 4, 6, 10, 12, 14])
    assert expected == BitFieldSet.intersection(bitfield1, bitfield2)
  end

  test "difference" do
    empty = MapSet.new()

    {:ok, bitfield1} = BitFieldSet.new(<<255>>, 8)
    {:ok, bitfield2} = BitFieldSet.new(<<0>>, 8)
    expected = MapSet.new(0..7)
    assert expected ==  BitFieldSet.difference(bitfield1, bitfield2)

    {:ok, bitfield1} = BitFieldSet.new(<<0>>, 8)
    {:ok, bitfield2} = BitFieldSet.new(<<255>>, 8)
    assert BitFieldSet.difference(bitfield1, bitfield2) == empty

    {:ok, bitfield1} = BitFieldSet.new(<<170>>, 8)
    {:ok, bitfield2} = BitFieldSet.new(<<170>>, 8)
    assert BitFieldSet.difference(bitfield1, bitfield2) == empty

    {:ok, bitfield1} = BitFieldSet.new(<<170>>, 8)
    {:ok, bitfield2} = BitFieldSet.new(<<85>>, 8)
    expected = MapSet.new([0, 2, 4, 6])
    assert expected == BitFieldSet.difference(bitfield1, bitfield2)
  end

  test "disjoint" do
    {:ok, bitfield1} = BitFieldSet.new(<<0, 255>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<255, 0>>, 16)
    {:ok, bitfield3} = BitFieldSet.new(<<128, 128>>, 16)

    assert BitFieldSet.disjoint?(bitfield1, bitfield2) == true
    assert BitFieldSet.disjoint?(bitfield1, bitfield3) == false
  end

  test "subset" do
    {:ok, bitfield1} = BitFieldSet.new(<<128>>, 8)
    {:ok, bitfield2} = BitFieldSet.new(<<255>>, 8)

    assert BitFieldSet.subset?(bitfield1, bitfield2) == true
    assert BitFieldSet.subset?(bitfield2, bitfield1) == false
  end

  test "equal" do
    {:ok, bitfield1} = BitFieldSet.new(<<0, 255>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<255, 0>>, 16)
    {:ok, bitfield3} = BitFieldSet.new(<<0, 255>>, 16)

    assert BitFieldSet.equal?(bitfield1, bitfield2) == false
    assert BitFieldSet.equal?(bitfield1, bitfield3) == true
  end

  test "union" do
    {:ok, bitfield1} = BitFieldSet.new(<<0, 255>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<255, 0>>, 16)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..15)

    {:ok, bitfield1} = BitFieldSet.new(<<255, 0>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<255, 0>>, 16)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..7)

    {:ok, bitfield1} = BitFieldSet.new(<<170, 0>>, 16)
    {:ok, bitfield2} = BitFieldSet.new(<<85, 0>>, 16)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..7)
  end
end
