defmodule BitFieldSet do
  @moduledoc """
  A bit field implementation using MapSets.

  Its main usecase is for BitTorrent implementations.
  """

  @opaque t :: %__MODULE__{size: pos_integer, pieces: %MapSet{map: non_neg_integer}, info_hash: any}
  defstruct(
    size: 0,
    pieces: MapSet.new,
    info_hash: nil
  )

  @doc """
  Create a new piece set given either a `size` (an integer denoting bit size)
  *or* some `content` (a binary, the size will be set from the bit size of this
  binary), and an optional `info_hash`, used to ensure only compatible
  bit-fields are compared.

      iex> BitFieldSet.new(16) |> BitFieldSet.to_binary
      <<0, 0>>

  The size will be taken from the input when a piece set is created with data:

      iex> BitFieldSet.new(<<128, 1>>) |> BitFieldSet.to_list
      [0, 15]

  The piece set can be given an `info_hash` as the second argument, it can be
  anything, and it defaults to `nil`.
  """
  @spec new(pos_integer | binary, any) :: t
  def new(content, info_hash \\ nil)
  def new(content_size, info_hash) when is_number(content_size) and content_size > 0 do
    %__MODULE__{info_hash: info_hash, size: content_size, pieces: MapSet.new}
  end
  def new(content, info_hash) when is_binary(content) do
    pieces = reduce_bits(content, fn
      {index, 1}, acc ->
        [index|acc]
      _, acc ->
        acc
    end)
    %__MODULE__{info_hash: info_hash, size: bit_size(content), pieces: MapSet.new(pieces)}
  end

  # Reduce the bits in the bytes in the bit-field
  defp reduce_bits(bytes, fun),
    do: do_reduce_bits(bytes, 0, [], fun)

  defp do_reduce_bits(<<>>, _index, acc, _fun),
    do: Enum.reverse acc
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

      iex> set = BitFieldSet.new(<<0b10101000>>)
      iex> BitFieldSet.set(set, 6) |> BitFieldSet.to_list
      [0, 2, 4, 6]

  """
  @spec set(t, non_neg_integer) :: t
  def set(%__MODULE__{pieces: pieces, size: size} = state, piece)
  when is_number(piece) and piece < size do
    %__MODULE__{state|pieces: MapSet.put(pieces, piece)}
  end

  @doc """
  Take a piece set and an index. The given index will get removed from the piece
  set and the updated piece set will get returned:

      iex> set = BitFieldSet.new(<<0b10101000>>)
      iex> BitFieldSet.remove(set, 2) |> BitFieldSet.to_list
      [0, 4]

  """
  @spec remove(t, non_neg_integer) :: t
  def remove(%__MODULE__{pieces: pieces, size: size} = state, piece)
  when is_number(piece) and piece < size do
    %__MODULE__{state|pieces: MapSet.delete(pieces, piece)}
  end

  @doc """
  Takes a piece set and a piece number and return `true` if the given piece number
  is present in the set; `false` otherwise.

      iex> set = BitFieldSet.new(<<0b10000001>>)
      iex> BitFieldSet.member?(set, 7)
      true
      iex> BitFieldSet.member?(set, 2)
      false

  """
  @spec member?(t, non_neg_integer) :: boolean
  def member?(%__MODULE__{pieces: pieces, size: size}, piece_number) when piece_number < size do
    MapSet.member?(pieces, piece_number)
  end

  @doc """
  Takes two piece sets with the same `info_hash`, and return `true` if both sets
  contain exactly the same pieces; and `false` otherwise.

      iex> a = BitFieldSet.new(<<0b10100110>>)
      iex> b = BitFieldSet.new(<<0b10100110>>)
      iex> BitFieldSet.equal?(a, b)
      true
      iex> c = BitFieldSet.new(<<0b11011011>>)
      iex> BitFieldSet.equal?(a, c)
      false

  """
  @spec equal?(t, t) :: boolean
  def equal?(%__MODULE__{pieces: a, info_hash: info_hash}, %__MODULE__{pieces: b, info_hash: info_hash}) do
    MapSet.equal?(a, b)
  end

  @doc """
  Takes two piece sets, a and b, who has the same `info_hash`, and return `true` if
  all the members of set a are also members of set b; `false` otherwise.

      iex> a = BitFieldSet.new(<<0b00000110>>)
      iex> b = BitFieldSet.new(<<0b00101110>>)
      iex> BitFieldSet.subset?(a, b)
      true
      iex> BitFieldSet.subset?(b, a)
      false

  """
  @spec subset?(t, t) :: boolean
  def subset?(%__MODULE__{pieces: a, info_hash: info_hash}, %__MODULE__{pieces: b, info_hash: info_hash}) do
    MapSet.subset?(a, b)
  end

  @doc """
  Takes two piece sets and return `true` if the two sets does not share any members,
  otherwise `false` will get returned.

      iex> a = BitFieldSet.new(<<0b00101110>>)
      iex> b = BitFieldSet.new(<<0b11010001>>)
      iex> c = BitFieldSet.new(<<0b11101000>>)
      iex> BitFieldSet.disjoint?(a, b)
      true
      iex> BitFieldSet.disjoint?(a, c)
      false

  """
  @spec disjoint?(t, t) :: boolean
  def disjoint?(%__MODULE__{pieces: a, info_hash: info_hash}, %__MODULE__{pieces: b, info_hash: info_hash}) do
    MapSet.disjoint?(a, b)
  end

  @doc """
  Takes two piece sets with the same `info_hash` and return a set containing the pieces
  that belong to both sets.

      iex> a = BitFieldSet.new(<<0b00101010>>)
      iex> b = BitFieldSet.new(<<0b10110011>>)
      iex> BitFieldSet.intersection(a, b)
      #MapSet<[2, 6]>

  """
  @spec intersection(t, t) :: MapSet.t
  def intersection(%__MODULE__{pieces: a, info_hash: info_hash}, %__MODULE__{pieces: b, info_hash: info_hash}) do
    MapSet.intersection(a, b)
  end

  @doc """
  Takes two piece sets with the same `info_hash` and return a set containing all
  members of both sets.

      iex> a = BitFieldSet.new(<<0b00101010>>)
      iex> b = BitFieldSet.new(<<0b10000000>>)
      iex> BitFieldSet.union(a, b)
      #MapSet<[0, 2, 4, 6]>

  """
  @spec union(t, t) :: MapSet.t
  def union(%__MODULE__{pieces: a, info_hash: info_hash}, %__MODULE__{pieces: b, info_hash: info_hash}) do
    MapSet.union(a, b)
  end

  @doc """
  Takes two piece sets, a and b, who both has the same `info_hash`, and return a MapSet
  containing the pieces in *a* without the pieces contained in *b*.

      iex> a = BitFieldSet.new(<<170>>)
      iex> b = BitFieldSet.new(<<85>>)
      iex> BitFieldSet.difference(a, b)
      #MapSet<[0, 2, 4, 6]>
      iex> BitFieldSet.difference(b, a)
      #MapSet<[1, 3, 5, 7]>

  """
  @spec difference(t, t) :: MapSet.t
  def difference(%__MODULE__{info_hash: info_hash, pieces: a}, %__MODULE__{info_hash: info_hash, pieces: b}) do
    MapSet.difference(a, b)
  end

  @doc """
  Take a piece set and return the number of its available pieces.

      iex> BitFieldSet.new(<<0b10101010>>) |> BitFieldSet.has
      4

  """
  @spec has(t) :: non_neg_integer
  def has(%__MODULE__{pieces: pieces}) do
    MapSet.size(pieces)
  end

  @doc """
  Take a piece set and return `true` if the set contains all the pieces,
  and `false` otherwise.

      iex> BitFieldSet.new(<<0b10011010>>) |> BitFieldSet.has_all?
      false
      iex> BitFieldSet.new(<<0b11111111>>) |> BitFieldSet.has_all?
      true

  """
  @spec has_all?(t) :: boolean
  def has_all?(%__MODULE__{pieces: pieces, size: size}) do
    MapSet.size(pieces) == size
  end

  @doc """
  Take a piece set and return the available pieces as a list.

      iex> BitFieldSet.new(<<0b10011010>>) |> BitFieldSet.to_list
      [0, 3, 4, 6]

  """
  @spec to_list(t) :: [non_neg_integer]
  def to_list(%__MODULE__{pieces: pieces}) do
    MapSet.to_list(pieces)
  end

  @doc """
  Take a piece set and return the bit field representation of the set.

      iex> BitFieldSet.new(<<0b10011010, 0b10000000>>) |> BitFieldSet.to_binary
      <<154, 128>>

  """
  @spec to_binary(t) :: binary
  def to_binary(%__MODULE__{size: size, pieces: pieces}) when size > 0 do
    have = MapSet.to_list(pieces)
    bit_range = 0..(size - 1)

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
