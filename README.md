# Bit Field Set

Store and manipulate a set of bit flags, mostly used for syncing the state over the wire between peers in a peer to peer network, such as BitTorrent.


## Usage

```elixir
# Create a new bit field set with the new command.
bitfield = BitFieldSet.new(<<0b00110001>>, "my_info_hash")
# => %BitFieldSet{info_hash: "my_info_hash", pieces: #MapSet<[2, 3, 7]>, size: 8}

# set the first bit
bitfield = BitFieldSet.set(bitfield, 0)
# => %BitFieldSet{info_hash: nil, pieces: #MapSet<[0, 2, 3, 7]>, size: 8}

bitfield = BitFieldSet.remove(bitfield, 3)
# => %BitFieldSet{info_hash: nil, pieces: #MapSet<[1, 2, 7]>, size: 8}

BitFieldSet.to_binary(bitfield) # => <<161>>
```


## Installation

Bit Field Set is [available in Hex](https://hex.pm/packages/bit_field_set), the package can be installed by adding  bit_field_set to your list of dependencies in `mix.exs`:

``` elixir
def deps do
  [{:bit_field_set, "~> 0.0.1"}]
end
```

This module does not need to be started as an application, just use it as is.


## Development

Fork the project and fetch the dependencies.

  * The project uses [QuickCheck for Elixir](https://github.com/Quviq/eqc_ex/) from [Quviq](http://quviq.com/) to test its behavior. Please download an follow the install instructions for QuickCheck Mini to run the property tests.

  * Benchmarks are performed by [Benchfella](https://github.com/alco/benchfella), a project by [Alexei Sholik](https://github.com/alco). Nothing special is needed besides fetching the mix dependencies.


## License

Copyright 2015 Martin Gausby

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.