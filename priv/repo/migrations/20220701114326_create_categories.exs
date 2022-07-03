defmodule GoldenLinks.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :category, :string
      add :description, :string
      timestamps()
    end
  end
end
