defmodule ChatGPT.AppFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChatGPT.App` context.
  """

  @doc """
  Generate a chat.
  """
  def chat_fixture(attrs \\ %{}) do
    {:ok, chat} =
      attrs
      |> Enum.into(%{
        answer: "some answer",
        question: "some question"
      })
      |> ChatGPT.App.create_chat()

    chat
  end
end
