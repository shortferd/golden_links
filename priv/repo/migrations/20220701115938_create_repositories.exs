defmodule GoldenLinks.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
      create table(:repositories) do
        add :awesome_category_id, references(:categories)
        add :repository, :string
        add :description, :string
        add :"days after last commit", :string
        add :"github stars", :string
        add :url, :string
        timestamps()
    end
  end
end
