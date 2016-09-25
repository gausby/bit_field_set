# Bit Field Set

[![Hex.pm](https://img.shields.io/hexpm/l/bit_field_set.svg "Apache 2.0 Licensed")](https://github.com/gausby/bit_field_set/blob/master/LICENSE)
[![Hex version](https://img.shields.io/hexpm/v/bit_field_set.svg "Hex version")](https://hex.pm/packages/bit_field_set)

Store and manipulate a set of bit flags, mostly used for syncing the state over the wire between peers in a peer to peer network, such as BitTorrent.


## Usage

```elixir
# Create a new bit field set with the new command.
# (initial content, size in bits, an optional info hash)
bitfield = BitFieldSet.new!(<<0b00110001>>, 8)
# => #BitFieldSet<[2, 3, 7]>

# set the first bit
bitfield = BitFieldSet.put(bitfield, 0)
# => #BitFieldSet<[0, 2, 3, 7]>

bitfield = BitFieldSet.delete(bitfield, 3)
# => #BitFieldSet<[0, 2, 7]>

BitFieldSet.to_binary(bitfield)
# => <<161>>
```


## Installation

Bit Field Set is [available in Hex](https://hex.pm/packages/bit_field_set), the package can be installed by adding  bit_field_set to your list of dependencies in `mix.exs`:

``` elixir
def deps do
  [{:bit_field_set, "~> 1.1.0"}]
end
```

This module does not need to be started as an application, just use it as is.


## Development

Fork the project and fetch the dependencies.

  * The project uses [QuickCheck for Elixir](https://github.com/Quviq/eqc_ex/) from [Quviq](http://quviq.com/) to test its behavior. Please download an follow the install instructions for QuickCheck Mini to run the property tests.

  * Benchmarks are performed by [Benchfella](https://github.com/alco/benchfella), a project by [Alexei Sholik](https://github.com/alco). Nothing special is needed besides fetching the mix dependencies.


## License

Copyright 2016 Martin Gausby

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
