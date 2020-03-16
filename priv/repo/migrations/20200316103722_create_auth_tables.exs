defmodule Demo.Repo.Migrations.CreateAuthTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :encrypted_password, :string
      add :confirmed_at, :naive_datetime

      timestamps()
    end
  end
end
