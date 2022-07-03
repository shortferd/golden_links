defmodule GoldenLinks.AwesomeRepository do
  alias GoldenLinks.AwesomeCategory
  use Ecto.Schema

  schema "repositories" do
    field :repository, :string
    field :description, :string
    field :"days after last commit", :string
    field :"github stars", :string
    field :url, :string
    belongs_to :awesome_category, AwesomeCategory
    timestamps()
  end
end
