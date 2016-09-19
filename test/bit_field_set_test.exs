defmodule BitFieldSetTest do
  use ExUnit.Case
  doctest BitFieldSet

  test "creating a new empty bitfield" do
    assert {:ok, %BitFieldSet{size: 32, pieces: 0}} = BitFieldSet.new(32)
  end

  test "creating a new bitfield with data" do
    bitfield = %BitFieldSet{size: 32, pieces: 0b10000000010000000010000000110000}
    assert {:ok, ^bitfield} = BitFieldSet.new(<<128, 64, 32, 48>>, 32)

    assert %BitFieldSet{size: 8, pieces: 0b00000100} = BitFieldSet.new!(<<4>>, 8)
  end

  test "bit fields should be able to hold sets of arbitrary sizes" do
    bitfield = %BitFieldSet{size: 33, pieces: 0b100000000100000000100000001100001}
    assert {:ok, ^bitfield} = BitFieldSet.new(<<128, 64, 32, 48, 128>>, 33)
    assert %BitFieldSet{size: 15, pieces: 0b100000000000000} = BitFieldSet.new!(<<128, 0>>, 15)
  end

  test "tmp" do
    bitfield = %BitFieldSet{size: 33, pieces: 0b100000000100000000100000001100001}
    assert {:ok, ^bitfield} = BitFieldSet.new(<<128, 64, 32, 48, 128>>, 33)
    assert [0] = BitFieldSet.to_list(BitFieldSet.new!(<<128, 0>>, 15))
  end


  test "bit fields should throw an error if bits are out of bounds" do
    assert {:error, :out_of_bounds} = BitFieldSet.new(<<128, 64, 32, 48, 129>>, 33)
    assert {:error, :out_of_bounds} = BitFieldSet.new(<<0::size(120)>>, 33)
  end

  test "turning a bitfield into a binary" do
    cases =
      [<<74, 0, 0>>,
       <<0, 74, 0>>,
       <<0, 0, 74>>,
       <<1, 255, 74>>]
    for bin <- cases do
      size = bit_size(bin)
      <<pieces::big-size(size)>> = bin
      assert ^bin = BitFieldSet.to_binary(%BitFieldSet{size: size, pieces: pieces})
    end

    assert <<0b10000000, 0, 0>> = BitFieldSet.to_binary(%BitFieldSet{size: 22, pieces: 0b1000000000000000000000})
    assert <<0b10000000, 0, 0>> = BitFieldSet.to_binary(%BitFieldSet{size: 24, pieces: 0b100000000000000000000000})

    assert <<255, 255, 252>> = BitFieldSet.to_binary(%BitFieldSet{size: 23, pieces: 0b111111111111111111111110})
    assert <<128, 0>> = BitFieldSet.to_binary(%BitFieldSet{size: 12, pieces: 0b100000000000})
  end

  test "getting bits" do
    bitfield = %BitFieldSet{size: 32, pieces: 0b10000000100000011111111100000001}

    assert BitFieldSet.member?(bitfield, 0)
    refute BitFieldSet.member?(bitfield, 1)
    assert BitFieldSet.member?(bitfield, 8)
    refute BitFieldSet.member?(bitfield, 14)
    assert BitFieldSet.member?(bitfield, 15)
    assert BitFieldSet.member?(bitfield, 16)

    refute BitFieldSet.member?(bitfield, 30)
    assert BitFieldSet.member?(bitfield, 31)
  end

  test "setting bits" do
    result =
      %BitFieldSet{size: 16, pieces: 0}
      |> BitFieldSet.put(2)
      |> BitFieldSet.put(4)
      |> BitFieldSet.put(6)
      |> BitFieldSet.put(8)
      |> BitFieldSet.put(15)

    assert result == %BitFieldSet{size: 16, pieces: 0b0010101010000001}
  end

  test "setting bits in an odd numbered set" do
    result =
      %BitFieldSet{size: 18, pieces: 0}
      |> BitFieldSet.put(0)
      |> BitFieldSet.put(4)
      |> BitFieldSet.put(6)
      |> BitFieldSet.put(8)
      |> BitFieldSet.put(17)

    assert result == %BitFieldSet{size: 18, pieces: 0b100010101000000001}

    bitfield = %BitFieldSet{size: 18, pieces: 0b111111110000000000}
    assert %BitFieldSet{size: 18, pieces: 0b111111111000000000} = BitFieldSet.put(bitfield, 8)
  end

  test "setting all bits using fill/1" do
    assert %BitFieldSet{size: 8, pieces: 0b11111111} =
      BitFieldSet.fill(%BitFieldSet{size: 8, pieces: 0})

    assert %BitFieldSet{size: 8, pieces: 0b11111111} =
      BitFieldSet.fill(%BitFieldSet{size: 8, pieces: 0b11100100})

    <<pieces::big-size(120)>> = <<255, 255, 255, 255, 255,
                                  255, 255, 255, 255, 255,
                                  255, 255, 255, 255, 255>>
    assert %BitFieldSet{size: 120, pieces: ^pieces} =
      BitFieldSet.fill(%BitFieldSet{size: 120, pieces: 0})

    assert %BitFieldSet{size: 1, pieces: 0b00000001} =
      BitFieldSet.fill(%BitFieldSet{size: 1, pieces: 0})

    assert %BitFieldSet{size: 17, pieces: 0b11111111111111111} =
      BitFieldSet.fill(%BitFieldSet{size: 17, pieces: 0})
  end

  test "removing bits" do
    assert %BitFieldSet{size: 8, pieces: 0} =
      BitFieldSet.delete(%BitFieldSet{size: 8, pieces: 0b00100000}, 2)

    assert %BitFieldSet{size: 8, pieces: 0b101010} =
      BitFieldSet.delete(%BitFieldSet{size: 8, pieces: 0b10101010}, 0)

    assert %BitFieldSet{size: 8, pieces: 0b10100010} =
      BitFieldSet.delete(%BitFieldSet{size: 8, pieces: 0b10101010}, 4)
  end

  test "counting the number of available pieces in a bitfield" do
    assert 8 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b11111111})
    assert 4 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b10101001})
    assert 3 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b101001})
    assert 2 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b1010})
    assert 1 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b1000})
    assert 0 = BitFieldSet.size(%BitFieldSet{size: 8, pieces: 0b00000000})

    assert 3 = BitFieldSet.size(%BitFieldSet{size: 24, pieces: 0b100000001000000010000000})
    assert 6 = BitFieldSet.size(%BitFieldSet{size: 24, pieces: 0b000010100000101000001010})
    assert 12 = BitFieldSet.size(%BitFieldSet{size: 24, pieces: 0b101010101010101010101010})

    assert 12 = BitFieldSet.size(%BitFieldSet{size: 23, pieces: 0b10101010101010101010101})
  end

  test "is full?" do
    assert BitFieldSet.is_full?(%BitFieldSet{size: 8, pieces: 0b11111111})
    refute BitFieldSet.is_full?(%BitFieldSet{size: 8, pieces: 0b11111110})
    refute BitFieldSet.is_full?(%BitFieldSet{size: 16, pieces: 0b1111111100000001})
    assert BitFieldSet.is_full?(%BitFieldSet{size: 16, pieces: 0b1111111111111111})
  end

  test "get available pieces for a bit-field as a list" do
    assert [1, 8] = BitFieldSet.to_list(%BitFieldSet{size: 16, pieces: 0b0100000010000000})
    assert [0, 8] = BitFieldSet.to_list(%BitFieldSet{size: 16, pieces: 0b1000000010000000})
    assert [8] = BitFieldSet.to_list(%BitFieldSet{size: 16, pieces: 0b0000000010000000})
    result = Enum.to_list(0..15)
    assert ^result = BitFieldSet.to_list(%BitFieldSet{size: 16, pieces: 0b1111111111111111})

    assert [15] = BitFieldSet.to_list(%BitFieldSet{size: 16, pieces: 0b00000000000000001})

    assert [0] = BitFieldSet.to_list(%BitFieldSet{size: 8, pieces: 0b10000000})
    assert [1] = BitFieldSet.to_list(%BitFieldSet{size: 8, pieces: 0b01000000})
    assert [5] = BitFieldSet.to_list(%BitFieldSet{size: 8, pieces: 0b00000100})
    assert [5, 7] = BitFieldSet.to_list(%BitFieldSet{size: 8, pieces: 0b00000101})

    assert [3, 5] = BitFieldSet.to_list(%BitFieldSet{size: 7, pieces: 0b0001010})

    assert [0] = BitFieldSet.to_list(%BitFieldSet{size: 15, pieces: 0b100000000000000})
  end

  test "intersection" do
    # present in both sets
    bitfield1 = %BitFieldSet{size: 16, pieces: 0b1011111001101010}
    bitfield2 = %BitFieldSet{size: 16, pieces: 0b0110101010111110}

    assert %BitFieldSet{size: 16, pieces: 0b0010101000101010} =
      BitFieldSet.intersection(bitfield1, bitfield2)

    assert %BitFieldSet{size: 16, pieces: 0b0010101000101010} =
      BitFieldSet.intersection(bitfield2, bitfield1)
  end

  test "difference" do
    empty = %BitFieldSet{size: 8, pieces: 0}
    bitfield1 = %BitFieldSet{size: 8, pieces: 0b11111111}
    bitfield2 = %BitFieldSet{size: 8, pieces: 0}
    bitfield3 = %BitFieldSet{size: 8, pieces: 0b10101010}
    bitfield4 = %BitFieldSet{size: 8, pieces: 0b01010101}

    assert ^bitfield1 = BitFieldSet.difference(bitfield1, bitfield2)
    assert ^empty = BitFieldSet.difference(empty, bitfield2)
    assert ^empty = BitFieldSet.difference(bitfield3, bitfield3)
    assert ^bitfield3 = BitFieldSet.difference(bitfield3, bitfield4)
    assert ^bitfield4 = BitFieldSet.difference(bitfield4, bitfield3)

    bitfield_a = %BitFieldSet{size: 8, pieces: 0b01100000}
    bitfield_b = %BitFieldSet{size: 8, pieces: 0b00111000}
    bitfield_c = %BitFieldSet{size: 8, pieces: 0b01000000}
    assert ^bitfield_c = BitFieldSet.difference(bitfield_a, bitfield_b)
  end

  test "disjoint?" do
    bitfield1 = %BitFieldSet{size: 16, pieces: 0b0000000011111111}
    bitfield2 = %BitFieldSet{size: 16, pieces: 0b1111111100000000}
    bitfield3 = %BitFieldSet{size: 16, pieces: 0b1000000010000000}

    assert BitFieldSet.disjoint?(bitfield1, bitfield2)
    refute BitFieldSet.disjoint?(bitfield1, bitfield3)
  end

  test "subset" do
    bitfield1 = %BitFieldSet{size: 8, pieces: 0b10000000}
    bitfield2 = %BitFieldSet{size: 8, pieces: 0b11111111}

    assert BitFieldSet.subset?(bitfield1, bitfield2)
    refute BitFieldSet.subset?(bitfield2, bitfield1)
  end

  test "equal" do
    bitfield1 = %BitFieldSet{size: 16, pieces: 0b0000000011111111}
    bitfield2 = %BitFieldSet{size: 16, pieces: 0b1111111100000000}

    refute BitFieldSet.equal?(bitfield1, bitfield2)
    assert BitFieldSet.equal?(bitfield1, bitfield1)
  end

  test "union" do
    bitfield_full = %BitFieldSet{size: 16, pieces: 0b1111111111111111}
    bitfield1 = %BitFieldSet{size: 16, pieces: 0b0000000011111111}
    bitfield2 = %BitFieldSet{size: 16, pieces: 0b1111111100000000}
    bitfield4 = %BitFieldSet{size: 16, pieces: 0b1010101000000000}
    bitfield5 = %BitFieldSet{size: 16, pieces: 0b0101010100000000}

    assert ^bitfield_full = BitFieldSet.union(bitfield1, bitfield2)
    assert ^bitfield1 = BitFieldSet.union(bitfield1, bitfield1)
    assert ^bitfield2 = BitFieldSet.union(bitfield2, bitfield2)
    assert ^bitfield2 = BitFieldSet.union(bitfield4, bitfield5)
  end
end
