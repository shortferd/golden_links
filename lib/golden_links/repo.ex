defmodule GoldenLinks.Repo do
  use Ecto.Repo,
    otp_app: :golden_links,
    adapter: Ecto.Adapters.Postgres
end
