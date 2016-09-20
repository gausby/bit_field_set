defmodule BitFieldSet do
  @moduledoc false

  use Bitwise

  @type piece_index :: non_neg_integer
  @type size :: non_neg_integer
  @type errors :: :out_of_bounds

  @opaque t :: %__MODULE__{size: size, pieces: non_neg_integer}
  defstruct size: 0, pieces: 0

  @doc """
  Create a new bit field set given a `size` (an integer denoting the
  bit size of the bit field) *and* some optional initialization
  `content` (a binary, the size of it should not exceed the size of
  the bit field).

      iex> BitFieldSet.new!(16) |> BitFieldSet.to_binary()
      <<0, 0>>

  The target size should be specified when a bit field is initialized
  with data.

      iex> BitFieldSet.new!(<<128, 1>>, 16)
      #BitFieldSet<[0, 15]>

  """
  @spec new(binary, size) :: {:ok, t} | {:error, errors}
  def new(data \\ <<>>, size)
  def new(<<>>, size), do: {:ok, %__MODULE__{size: size, pieces: 0}}
  def new(data, size) when bit_size(data) - size < 8 do
    actual_size = bitfield_size(size)
    <<pieces::big-size(actual_size)>> = data

    with bitfield = %__MODULE__{size: size, pieces: pieces},
         {:ok, bitfield} <- validate_trailing_bits(bitfield),
         {:ok, bitfield} <- drop_tailing_bits(bitfield) do
      {:ok, bitfield}
    end
  end
  def new(_content, _size), do: {:error, :out_of_bounds}

  # Trailing bits should never be set. They can occur if the bit
  # field set it not divisible by eight. If they are set we should
  # throw an error.
  defp validate_trailing_bits(%__MODULE__{size: size} = bitfield)
  when rem(size, 8) == 0 do
    {:ok, bitfield}
  end
  defp validate_trailing_bits(%__MODULE__{} = bitfield) do
    tailing_bits = bitfield_size(bitfield) - bitfield.size
    tailing_bit_mask = (1 <<< tailing_bits) - 1
    if band(bitfield.pieces, tailing_bit_mask) == 0 do
      {:ok, bitfield}
    else
      {:error, :out_of_bounds}
    end
  end

  # we use the tailing bits for the internal representation
  defp drop_tailing_bits(%__MODULE__{size: size} = bitfield)
  when rem(size, 8) == 0 do
    {:ok, bitfield}
  end
  defp drop_tailing_bits(bitfield) do
    tailing_bits = bitfield_size(bitfield) - bitfield.size
    {:ok, %{bitfield|pieces: bitfield.pieces >>> tailing_bits}}
  end


  @doc """
  Like `new/2` but will throw an error on initialization failure
  """
  @spec new!(binary, size) :: t
  def new!(content \\ <<>>, size) do
    {:ok, set} = new(content, size)
    set
  end


  @doc """
  Takes two bit field sets of the same size, and return `true` if both
  sets contain exactly the same pieces; and `false` otherwise.

      iex> a = BitFieldSet.new!(<<0b10100110>>, 8)
      iex> b = BitFieldSet.new!(<<0b10100110>>, 8)
      iex> BitFieldSet.equal?(a, b)
      true
      iex> c = BitFieldSet.new!(<<0b11011011>>, 8)
      iex> BitFieldSet.equal?(a, c)
      false

  """
  @spec equal?(t, t) :: boolean
  def equal?(%__MODULE__{size: size, pieces: pieces},
             %__MODULE__{size: size, pieces: pieces}), do: true
  def equal?(_, _), do: false


  @doc """
  Takes a bit field set and a piece number and return `true` if the
  given piece number is present in the set; `false` otherwise.

      iex> set = BitFieldSet.new!(<<0b10000001>>, 8)
      iex> BitFieldSet.member?(set, 7)
      true
      iex> BitFieldSet.member?(set, 2)
      false

  """
  @spec member?(t, piece_index) :: boolean
  def member?(%__MODULE__{} = bitfield, piece_index) do
    piece = get_piece_index(bitfield, piece_index)
    band(bitfield.pieces, piece) != 0
  end


  @doc """
  Take a bit field set and an piece index and add it to the bit
  field. The updated piece set will get returned:

      iex> a = BitFieldSet.new!(<<0b10101000>>, 8)
      iex> BitFieldSet.put(a, 6)
      #BitFieldSet<[0, 2, 4, 6]>

  """
  @spec put(t, piece_index) :: t
  def put(%__MODULE__{size: size, pieces: pieces} = bitfield, piece_index)
  when piece_index < size do
    piece = get_piece_index(bitfield, piece_index)
    %{bitfield|pieces: bor(pieces, piece)}
  end


  @doc """
  Take a bit field set and an index. The given index will get removed
  from the bit field set and the updated bit field set will get
  returned:

      iex> set = BitFieldSet.new!(<<0b10101000>>, 8)
      iex> BitFieldSet.delete(set, 2)
      #BitFieldSet<[0, 4]>

  """
  @spec delete(t, piece_index) :: t
  def delete(%__MODULE__{pieces: pieces} = bitfield, piece_index) do
    if member?(bitfield, piece_index) do
      piece = get_piece_index(bitfield, piece_index)
      %{bitfield|pieces: pieces - piece}
    else
      bitfield
    end
  end


  @doc """
  Set all the bits to on in the bit field set.

      iex> set = BitFieldSet.new!(<<0b10100110>>, 8)
      iex> BitFieldSet.fill(set)
      #BitFieldSet<[0, 1, 2, 3, 4, 5, 6, 7]>

  """
  @spec fill(t) :: t
  def fill(%__MODULE__{size: size} = bitfield) do
    %{bitfield|pieces: (1 <<< size) - 1}
  end


  @doc """
  Take a bit field set and return `true` if the set contains all the
  pieces, and `false` otherwise.

      iex> BitFieldSet.new!(<<0b10011010>>, 8) |> BitFieldSet.is_full?()
      false
      iex> BitFieldSet.new!(<<0b11111111>>, 8) |> BitFieldSet.is_full?()
      true

  """
  @spec is_full?(t) :: boolean
  def is_full?(%__MODULE__{pieces: pieces, size: size}) do
    pieces == (1 <<< size) - 1
  end


  @doc """
  Takes two bit field sets of the same size and return a set
  containing the pieces that belong to both sets.

      iex> a = BitFieldSet.new!(<<0b00101010>>, 8)
      iex> b = BitFieldSet.new!(<<0b10110011>>, 8)
      iex> BitFieldSet.intersection(a, b)
      #BitFieldSet<[2, 6]>

  """
  @spec intersection(t, t) :: t
  def intersection(%__MODULE__{size: size, pieces: a} = bitfield,
                   %__MODULE__{size: size, pieces: b}) do
    %{bitfield|pieces: band(b, a)}
  end


  @doc """
  Takes two bit field sets, a and b, who both of the same size, and
  returns a set containing the pieces in *a* without the pieces in
  *b*.

      iex> a = BitFieldSet.new!(<<170>>, 8)
      iex> b = BitFieldSet.new!(<<85>>, 8)
      iex> BitFieldSet.difference(a, b)
      #BitFieldSet<[0, 2, 4, 6]>
      iex> BitFieldSet.difference(b, a)
      #BitFieldSet<[1, 3, 5, 7]>

  """
  @spec difference(t, t) :: t
  def difference(%__MODULE__{size: size, pieces: a} = bitfield,
                 %__MODULE__{size: size, pieces: b}) do
    %{bitfield|pieces: filter_not_in(a, b, 0, 0)}
  end


  @doc """
  Takes two bit field sets of the same size and returns a set
  containing all members of both sets.

      iex> a = BitFieldSet.new!(<<0b00101010>>, 8)
      iex> b = BitFieldSet.new!(<<0b10000000>>, 8)
      iex> BitFieldSet.union(a, b)
      #BitFieldSet<[0, 2, 4, 6]>

  """
  @spec union(t, t) :: t
  def union(%__MODULE__{size: size, pieces: a} = bitfield,
            %__MODULE__{size: size, pieces: b}) do
    %{bitfield|pieces: bor(a, b)}
  end


  @doc """
  Takes two bit field sets, a and b, who has the same size, and return
  `true` if all the members of set a are also members of set b;
  `false` otherwise.

      iex> a = BitFieldSet.new!(<<0b00000110>>, 8)
      iex> b = BitFieldSet.new!(<<0b00101110>>, 8)
      iex> BitFieldSet.subset?(a, b)
      true
      iex> BitFieldSet.subset?(b, a)
      false

  """
  @spec subset?(t, t) :: boolean
  def subset?(%__MODULE__{size: size, pieces: a},
              %__MODULE__{size: size, pieces: b}) do
    band(b, a) == a
  end


  @doc """
  Takes two bit field sets and return `true` if the two bit fields
  does not share any members, otherwise `false` will get returned.

      iex> a = BitFieldSet.new!(<<0b00101110>>, 8)
      iex> b = BitFieldSet.new!(<<0b11010001>>, 8)
      iex> c = BitFieldSet.new!(<<0b11101000>>, 8)
      iex> BitFieldSet.disjoint?(a, b)
      true
      iex> BitFieldSet.disjoint?(a, c)
      false

  """
  @spec disjoint?(t, t) :: boolean
  def disjoint?(%__MODULE__{pieces: a, size: size},
                %__MODULE__{pieces: b, size: size}) do
    band(b, a) == 0
  end


  @doc """
  Take a bit field set and return the number of its available pieces.

      iex> BitFieldSet.new!(<<0b10101010>>, 8) |> BitFieldSet.size()
      4

  """
  @spec size(t) :: non_neg_integer
  def size(%__MODULE__{pieces: pieces}) do
    count_enabled_bits(pieces, 0)
  end


  @doc """
  Takes a bit field set and returns a binary representation of the set.

      iex> a = BitFieldSet.new!(<<0b10011010, 0b10000000>>, 16)
      iex> BitFieldSet.to_binary(a)
      <<154, 128>>

  """
  @spec to_binary(t) :: binary
  def to_binary(%__MODULE__{pieces: pieces, size: size}) do
    byte_size = bitfield_size(size)
    tailing_bits = byte_size - size
    bitfield = pieces <<< tailing_bits
    <<bitfield::big-size(byte_size)>>
  end


  @doc """
  Take a bit field set and returns the available pieces as a list.

      iex> BitFieldSet.new!(<<0b10011010>>, 8) |> BitFieldSet.to_list()
      [0, 3, 4, 6]

  """
  @spec to_list(t) :: [piece_index]
  def to_list(%__MODULE__{pieces: pieces, size: size}) do
    do_to_list(pieces, size - 1, [])
  end


  # helpers ============================================================
  defp do_to_list(0, _, acc), do: acc
  defp do_to_list(pieces, piece_index, acc) do
    acc = if (pieces &&& 1) == 0, do: acc, else: [piece_index|acc]
    do_to_list(pieces >>> 1, piece_index - 1, acc)
  end

  defp get_piece_index(%__MODULE__{size: size}, piece_index) do
    1 <<< (size - (piece_index + 1))
  end

  # calculate the size of the bit field in bytes (divisible by 8)
  defp bitfield_size(%__MODULE__{size: size}), do: bitfield_size(size)
  defp bitfield_size(size) when is_integer(size) do
    tail = if (rem(size, 8) != 0), do: 1, else: 0
    (div(size, 8) + tail) * 8
  end

  # count the 'on' bits in the bit field
  defp count_enabled_bits(0, acc), do: acc
  defp count_enabled_bits(pieces, acc) do
    # check if the least significant bit is a 1 and increment the
    # accumulator if so; then shift the pieces and recurse
    count_enabled_bits(pieces >>> 1, acc + (pieces &&& 1))
  end

  # return bits present in a that is not present in b
  defp filter_not_in(0, _, _, acc), do: acc
  defp filter_not_in(a, b, counter, acc) do
    in_a? = band(a, 1) == 1
    in_b? = band(b, 1) == 1
    acc =
      if in_a? and not in_b? do
        acc + (1 <<< counter)
      else
        acc
      end

    filter_not_in(a >>> 1, b >>> 1, counter + 1, acc)
  end


  # protocols ==========================================================
  defimpl Enumerable do
    def reduce(source, acc, fun) do
      Enumerable.List.reduce(BitFieldSet.to_list(source), acc, fun)
    end

    def member?(source , value) do
      {:ok, BitFieldSet.member?(source, value)}
    end

    def count(source) do
      {:ok, BitFieldSet.size(source)}
    end
  end

  defimpl Collectable do
    def into(original) do
      {original, fn
        acc, {:cont, value} ->
          BitFieldSet.put(acc, value)

        acc, :done ->
          acc

        _, :halt ->
          :ok
      end}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(source, opts) do
      opts = %Inspect.Opts{opts|charlists: :as_lists}
      concat ["#BitFieldSet<", Inspect.List.inspect(BitFieldSet.to_list(source), opts), ">"]
    end
  end
end
