defmodule Conekta.Mixfile do
  use Mix.Project

  @description """
    Elixir library for Conekta api calls
  """

  def project do
    [app: :conekta,
     version: "1.1.2",
     description: @description,
     name: "Conekta",
     elixir: "~> 1.10",
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     source_url: "https://github.com/echavezNS/conekta-elixir.git"]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [{:credo, "~> 1.4", only: [:dev, :test], runtime: false},
     {:httpoison, "~> 1.7 or ~> 2.2"},
     {:poison, "~> 5.0 or ~> 6.0"},
     {:mock, "~> 0.3.0", only: :test},
     {:ex_doc, "~> 0.22", only: :dev, runtime: false}]
  end

  defp package do
    [ maintainers: ["Jorge Chavez"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/echavezNS/conekta-elixir.git"} ]
  end

end
