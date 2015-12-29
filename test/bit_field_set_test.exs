defmodule BitFieldSetTest do
  use ExUnit.Case
  doctest BitFieldSet

  test "creating a new bitfield" do
    bitfield = BitFieldSet.new(32)
    expected = MapSet.new
    assert %BitFieldSet{size: 32, pieces: ^expected} = bitfield
  end

  test "creating a new bitfield with data" do
    bitfield = BitFieldSet.new(<<128, 64, 32, 48>>)

    expected = MapSet.new([0, 9, 18, 26, 27])
    assert %BitFieldSet{size: 32, pieces: ^expected} = bitfield
  end

  test "turning a bitfield into a binary" do
    result =
      BitFieldSet.new(<<74, 0, 0>>)
      |> BitFieldSet.to_binary
    expected = <<74, 0, 0>>
    assert result == expected

    result =
      BitFieldSet.new(<<0, 74, 0>>)
      |> BitFieldSet.to_binary
    expected = <<0, 74, 0>>
    assert result == expected

    result =
      BitFieldSet.new(<<0, 0, 74>>)
      |> BitFieldSet.to_binary
    expected = <<0, 0, 74>>
    assert result == expected

    result =
      BitFieldSet.new(<<1, 255, 74>>)
      |> BitFieldSet.to_binary
    expected = <<1, 255, 74>>
    assert result == expected
  end

  test "getting bits" do
    bitfield = BitFieldSet.new(<<128, 129, 255, 1>>)

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
      BitFieldSet.new(16)
      |> BitFieldSet.set(2)
      |> BitFieldSet.set(4)
      |> BitFieldSet.set(6)
      |> BitFieldSet.set(8)
      |> BitFieldSet.set(15)

    expected = <<42, 129>>
    assert BitFieldSet.to_binary(result) == expected
  end

  test "removing bits" do
    bitfield =
      BitFieldSet.new(8)
      |> BitFieldSet.set(2)
      |> BitFieldSet.remove(2)
    assert BitFieldSet.to_binary(bitfield) == <<0>>

    bitfield =
      BitFieldSet.new(8)
      |> BitFieldSet.set(0)
      |> BitFieldSet.set(2)
      |> BitFieldSet.set(4)
      |> BitFieldSet.set(6) # 10101010
      |> BitFieldSet.remove(0) # 101010
    assert BitFieldSet.to_binary(bitfield) == <<42>>
  end

  test "counting the available pieces in a bitfield" do
    assert BitFieldSet.has(BitFieldSet.new(<<255>>)) == 8
    assert BitFieldSet.has(BitFieldSet.new(<<170>>)) == 4
    assert BitFieldSet.has(BitFieldSet.new(<<42>>)) == 3
    assert BitFieldSet.has(BitFieldSet.new(<<10>>)) == 2
    assert BitFieldSet.has(BitFieldSet.new(<<1>>)) == 1
    assert BitFieldSet.has(BitFieldSet.new(<<0>>)) == 0

    assert BitFieldSet.has(BitFieldSet.new(<<1,1,1>>)) == 3
    assert BitFieldSet.has(BitFieldSet.new(<<10,10,10>>)) == 6
    assert BitFieldSet.has(BitFieldSet.new(<<170,170,170>>)) == 12
  end

  test "has all" do
    assert BitFieldSet.has_all?(BitFieldSet.new(<<255>>)) == true
    assert BitFieldSet.has_all?(BitFieldSet.new(<<254>>)) == false
    assert BitFieldSet.has_all?(BitFieldSet.new(<<255, 1>>)) == false
    assert BitFieldSet.has_all?(BitFieldSet.new(<<255, 255>>)) == true
  end

  test "get available pieces for a bit-field as a list" do
    assert BitFieldSet.to_list(BitFieldSet.new(<<128, 128>>)) == [0, 8]
    assert BitFieldSet.to_list(BitFieldSet.new(<<255, 255>>)) == Enum.to_list(0..15)
  end

  test "intersection" do
    bitfield1 = BitFieldSet.new(<<190, 106>>)
    bitfield2 = BitFieldSet.new(<<106, 190>>)

    expected = MapSet.new([2, 4, 6, 10, 12, 14])
    assert expected == BitFieldSet.intersection(bitfield1, bitfield2)
  end

  test "difference" do
    empty = MapSet.new()

    bitfield1 = BitFieldSet.new(<<255>>)
    bitfield2 = BitFieldSet.new(<<0>>)
    expected = MapSet.new(0..7)
    assert expected ==  BitFieldSet.difference(bitfield1, bitfield2)

    bitfield1 = BitFieldSet.new(<<0>>)
    bitfield2 = BitFieldSet.new(<<255>>)
    assert BitFieldSet.difference(bitfield1, bitfield2) == empty

    bitfield1 = BitFieldSet.new(<<170>>)
    bitfield2 = BitFieldSet.new(<<170>>)
    assert BitFieldSet.difference(bitfield1, bitfield2) == empty

    bitfield1 = BitFieldSet.new(<<170>>)
    bitfield2 = BitFieldSet.new(<<85>>)
    expected = MapSet.new([0, 2, 4, 6])
    assert expected == BitFieldSet.difference(bitfield1, bitfield2)
  end

  test "disjoint" do
    bitfield1 = BitFieldSet.new(<<0, 255>>)
    bitfield2 = BitFieldSet.new(<<255, 0>>)
    bitfield3 = BitFieldSet.new(<<128, 128>>)

    assert BitFieldSet.disjoint?(bitfield1, bitfield2) == true
    assert BitFieldSet.disjoint?(bitfield1, bitfield3) == false
  end

  test "subset" do
    bitfield1 = BitFieldSet.new(<<128>>)
    bitfield2 = BitFieldSet.new(<<255>>)

    assert BitFieldSet.subset?(bitfield1, bitfield2) == true
    assert BitFieldSet.subset?(bitfield2, bitfield1) == false
  end

  test "equal" do
    bitfield1 = BitFieldSet.new(<<0, 255>>)
    bitfield2 = BitFieldSet.new(<<255, 0>>)
    bitfield3 = BitFieldSet.new(<<0, 255>>)

    assert BitFieldSet.equal?(bitfield1, bitfield2) == false
    assert BitFieldSet.equal?(bitfield1, bitfield3) == true
  end

  test "union" do
    bitfield1 = BitFieldSet.new(<<0, 255>>)
    bitfield2 = BitFieldSet.new(<<255, 0>>)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..15)

    bitfield1 = BitFieldSet.new(<<255, 0>>)
    bitfield2 = BitFieldSet.new(<<255, 0>>)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..7)

    bitfield1 = BitFieldSet.new(<<170, 0>>)
    bitfield2 = BitFieldSet.new(<<85, 0>>)
    assert BitFieldSet.union(bitfield1, bitfield2) == MapSet.new(0..7)
  end
end
