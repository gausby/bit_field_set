defmodule BitFieldSet do
  @moduledoc """
  A bit field implementation using MapSets.

  Its main usecase is for BitTorrent implementations.
  """

  alias __MODULE__, as: Set

  @opaque t :: %__MODULE__{size: pos_integer, pieces: %MapSet{map: non_neg_integer}, info_hash: any}
  defstruct(
    size: 0,
    pieces: MapSet.new,
    info_hash: nil
  )

  @doc """
  Create a new piece set given either a `size` (an integer denoting bit size)
  *or* some `content` (a binary, the size will be set from the bit size of this
  binary) *and* a `size`.

      iex> BitFieldSet.new!(16) |> BitFieldSet.to_binary
      <<0, 0>>

  The size will be taken from the input when a piece set is created with data:

      iex> BitFieldSet.new!(<<128, 1>>, 16) |> BitFieldSet.to_list
      [0, 15]

  An optional `info_hash` can be given as the third argument, which will ensure
  only compatible bit-fields are compared.
  """
  @spec new(binary, pos_integer, any) :: t
  def new(content \\ <<>>, size, info_hash \\ nil)
  def new(content, size, info_hash) when bit_size(content) - size < 8 do
    pieces =
      reduce_bits(content, fn
        {index, 1}, acc ->
          [index|acc]

        _, acc ->
          acc
      end)

    # check for out of bounds in least significant bit
    case pieces do
      [biggest|_rest] when biggest >= size ->
        {:error, :out_of_bounds}

      set ->
        {:ok, %Set{info_hash: info_hash, size: size, pieces: MapSet.new(set)}}
    end
  end
  def new(_content, _size, _info_hash) do
    {:error, :out_of_bounds}
  end

  @spec new!(binary, pos_integer, any) :: t
  def new!(content \\ <<>>, content_size, info_hash \\ nil)
  def new!(content, content_size, info_hash) do
    {:ok, set} = new(content, content_size, info_hash)
    set
  end

  # Reduce the bits in the bytes in the bit-field
  defp reduce_bits(bytes, fun),
    do: do_reduce_bits(bytes, 0, [], fun)

  defp do_reduce_bits(<<>>, _index, acc, _fun),
    do: acc
  defp do_reduce_bits(<<byte::integer, rest::binary>>, index, acc, fun) do
    {index, acc} =
      number_to_padded_bits(byte)
      |> Enum.reduce({index, acc}, fn bit, {index, acc} ->
           {index + 1, fun.({index, bit}, acc)}
         end)

    do_reduce_bits(rest, index, acc, fun)
  end

  @pad [0, 0, 0, 0, 0, 0, 0 ,0]
  defp number_to_padded_bits(n) do
    digits = Integer.digits(n, 2)
    Enum.take(@pad, 8 - length digits) ++ digits
  end

  @doc """
  Take a piece set and an index. The given index will get added to the piece
  set and the updated piece set will get returned:

      iex> {:ok, set} = BitFieldSet.new(<<0b10101000>>, 8)
      iex> BitFieldSet.set(set, 6) |> BitFieldSet.to_list
      [0, 2, 4, 6]

  """
  @spec set(t, non_neg_integer) :: t
  def set(%Set{pieces: pieces, size: size} = state, piece)
  when is_number(piece) and piece < size do
    %Set{state|pieces: MapSet.put(pieces, piece)}
  end

  @doc """
  Set all the bits to true in the set.

      iex> {:ok, set} = BitFieldSet.new(<<0b10100110>>, 8)
      iex> BitFieldSet.set_all(set) |> BitFieldSet.has_all?
      true

  """
  @spec set_all(t) :: t
  def set_all(%Set{size: size} = state) do
    %Set{state|pieces: MapSet.new(0..(size - 1))}
  end

  @doc """
  Take a piece set and an index. The given index will get removed from the piece
  set and the updated piece set will get returned:

      iex> {:ok, set} = BitFieldSet.new(<<0b10101000>>, 8)
      iex> BitFieldSet.remove(set, 2) |> BitFieldSet.to_list
      [0, 4]

  """
  @spec remove(t, non_neg_integer) :: t
  def remove(%Set{pieces: pieces, size: size} = state, piece)
  when is_number(piece) and piece < size do
    %Set{state|pieces: MapSet.delete(pieces, piece)}
  end

  @doc """
  Takes a piece set and a piece number and return `true` if the given piece number
  is present in the set; `false` otherwise.

      iex> {:ok, set} = BitFieldSet.new(<<0b10000001>>, 8)
      iex> BitFieldSet.member?(set, 7)
      true
      iex> BitFieldSet.member?(set, 2)
      false

  """
  @spec member?(t, non_neg_integer) :: boolean
  def member?(%Set{pieces: pieces, size: size}, piece_number) when piece_number < size do
    MapSet.member?(pieces, piece_number)
  end

  @doc """
  Takes two piece sets with the same `info_hash`, and return `true` if both sets
  contain exactly the same pieces; and `false` otherwise.

      iex> {:ok, a} = BitFieldSet.new(<<0b10100110>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<0b10100110>>, 8)
      iex> BitFieldSet.equal?(a, b)
      true
      iex> {:ok, c} = BitFieldSet.new(<<0b11011011>>, 8)
      iex> BitFieldSet.equal?(a, c)
      false

  """
  @spec equal?(t, t) :: boolean
  def equal?(%Set{pieces: a, info_hash: info_hash}, %Set{pieces: b, info_hash: info_hash}) do
    MapSet.equal?(a, b)
  end

  @doc """
  Takes two piece sets, a and b, who has the same `info_hash`, and return `true` if
  all the members of set a are also members of set b; `false` otherwise.

      iex> {:ok, a} = BitFieldSet.new(<<0b00000110>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<0b00101110>>, 8)
      iex> BitFieldSet.subset?(a, b)
      true
      iex> BitFieldSet.subset?(b, a)
      false

  """
  @spec subset?(t, t) :: boolean
  def subset?(%Set{pieces: a, info_hash: info_hash}, %Set{pieces: b, info_hash: info_hash}) do
    MapSet.subset?(a, b)
  end

  @doc """
  Takes two piece sets and return `true` if the two sets does not share any members,
  otherwise `false` will get returned.

      iex> {:ok, a} = BitFieldSet.new(<<0b00101110>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<0b11010001>>, 8)
      iex> {:ok, c} = BitFieldSet.new(<<0b11101000>>, 8)
      iex> BitFieldSet.disjoint?(a, b)
      true
      iex> BitFieldSet.disjoint?(a, c)
      false

  """
  @spec disjoint?(t, t) :: boolean
  def disjoint?(%Set{pieces: a, info_hash: info_hash}, %Set{pieces: b, info_hash: info_hash}) do
    MapSet.disjoint?(a, b)
  end

  @doc """
  Takes two piece sets with the same `info_hash` and return a set containing the pieces
  that belong to both sets.

      iex> {:ok, a} = BitFieldSet.new(<<0b00101010>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<0b10110011>>, 8)
      iex> BitFieldSet.intersection(a, b)
      #MapSet<[2, 6]>

  """
  @spec intersection(t, t) :: MapSet.t
  def intersection(%Set{pieces: a, info_hash: info_hash}, %Set{pieces: b, info_hash: info_hash}) do
    MapSet.intersection(a, b)
  end

  @doc """
  Takes two piece sets with the same `info_hash` and return a set containing all
  members of both sets.

      iex> {:ok, a} = BitFieldSet.new(<<0b00101010>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<0b10000000>>, 8)
      iex> BitFieldSet.union(a, b)
      #MapSet<[0, 2, 4, 6]>

  """
  @spec union(t, t) :: MapSet.t
  def union(%Set{pieces: a, info_hash: info_hash}, %Set{pieces: b, info_hash: info_hash}) do
    MapSet.union(a, b)
  end

  @doc """
  Takes two piece sets, a and b, who both has the same `info_hash`, and return a MapSet
  containing the pieces in *a* without the pieces contained in *b*.

      iex> {:ok, a} = BitFieldSet.new(<<170>>, 8)
      iex> {:ok, b} = BitFieldSet.new(<<85>>, 8)
      iex> BitFieldSet.difference(a, b)
      #MapSet<[0, 2, 4, 6]>
      iex> BitFieldSet.difference(b, a)
      #MapSet<[1, 3, 5, 7]>

  """
  @spec difference(t, t) :: MapSet.t
  def difference(%Set{info_hash: info_hash, pieces: a}, %Set{info_hash: info_hash, pieces: b}) do
    MapSet.difference(a, b)
  end

  @doc """
  Return true if the given set is empty and false otherwise.

      iex> BitFieldSet.new!(<<0b00000000>>, 8) |> BitFieldSet.empty?
      true

      iex> BitFieldSet.new!(<<0b10101010>>, 8) |> BitFieldSet.empty?
      false
  """
  @spec empty?(t) :: boolean
  def empty?(%Set{pieces: pieces}) do
    MapSet.size(pieces) == 0
  end

  @doc """
  Take a piece set and return the number of its available pieces.

      iex> BitFieldSet.new!(<<0b10101010>>, 8) |> BitFieldSet.has
      4

  """
  @spec has(t) :: non_neg_integer
  def has(%Set{pieces: pieces}) do
    MapSet.size(pieces)
  end

  @doc """
  Take a piece set and return `true` if the set contains all the pieces,
  and `false` otherwise.

      iex> BitFieldSet.new!(<<0b10011010>>, 8) |> BitFieldSet.has_all?
      false
      iex> BitFieldSet.new!(<<0b11111111>>, 8) |> BitFieldSet.has_all?
      true

  """
  @spec has_all?(t) :: boolean
  def has_all?(%Set{pieces: pieces, size: size}) do
    MapSet.size(pieces) == size
  end

  @doc """
  Take a piece set and return the available pieces as a list.

      iex> BitFieldSet.new!(<<0b10011010>>, 8) |> BitFieldSet.to_list
      [0, 3, 4, 6]

  """
  @spec to_list(t) :: [non_neg_integer]
  def to_list(%Set{pieces: pieces, size: size}) when size <= 40 do
    MapSet.to_list(pieces)
  end
  def to_list(%Set{pieces: pieces}) do
    MapSet.to_list(pieces) |> Enum.sort
  end

  @doc """
  Take a piece set and return the bit field representation of the set.

      iex> BitFieldSet.new!(<<0b10011010, 0b10000000>>, 16) |> BitFieldSet.to_binary
      <<154, 128>>

  """
  @spec to_binary(t) :: binary
  def to_binary(%Set{size: size} = set) when size > 0 do
    have = to_list(set)
    bit_range = 0..(div(size, 8) + (if rem(size, 8) == 0, do: 0, else: 1)) * 8

    Stream.transform(bit_range, have, fn
      # is the same
      i, [i|rest] ->
        {[1], rest}
      # is not the same
      _, rest ->
        {[0], rest}
    end)
    |> Stream.chunk(8)
    |> Enum.map(&(Integer.undigits(&1, 2)))
    |> IO.iodata_to_binary
  end
end
