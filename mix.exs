defmodule BitFieldSet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bit_field_set,
      version: "1.2.3",
      elixir: "~> 1.2",
      test_pattern: "*_{test,eqc}.exs",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application() do
    [applications: [:logger]]
  end

  defp description() do
    """
    Store and manipulate a set of bit flags, mostly used for syncing the state
    between peers in a peer to peer network, such as BitTorrent.
    """
  end

  def package() do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Martin Gausby"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/gausby/bit_field_set",
        "Issues" => "https://github.com/gausby/bit_field_set/issues"
      }
    ]
  end

  defp deps() do
    [
      {:ex_doc, "~> 0.20.0", only: :dev},
      {:eqc_ex, "~> 1.4.2", only: [:test, :dev]},
      {:benchfella, "~> 0.3.4", only: :dev}
    ]
  end
end
