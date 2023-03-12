defmodule ChatGPT.App.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chats" do
    field :answer, :string
    field :question, :string

    belongs_to :parent, __MODULE__

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:question, :answer, :parent_id])
    |> validate_required([:question, :answer])
  end
end
