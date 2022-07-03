defmodule GoldenLinks.AwesomeCategory do
  alias GoldenLinks.AwesomeRepository
  use Ecto.Schema

  schema "categories" do
    field :category, :string
    field :description, :string
    has_many :repositories, AwesomeRepository
    timestamps()
  end
end
