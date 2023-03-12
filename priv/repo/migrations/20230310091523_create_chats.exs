defmodule ChatGPT.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :question, :string
      add :answer, :string

      add :parent_id, references(:chats)

      timestamps()
    end
  end
end
