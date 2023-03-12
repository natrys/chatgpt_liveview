defmodule ChatGPT.AppTest do
  use ChatGPT.DataCase

  alias ChatGPT.App

  describe "chats" do
    alias ChatGPT.App.Chat

    import ChatGPT.AppFixtures

    @invalid_attrs %{answer: nil, question: nil}

    test "list_chats/0 returns all chats" do
      chat = chat_fixture()
      assert App.list_chats() == [chat]
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert App.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with valid data creates a chat" do
      valid_attrs = %{answer: "some answer", question: "some question"}

      assert {:ok, %Chat{} = chat} = App.create_chat(valid_attrs)
      assert chat.answer == "some answer"
      assert chat.question == "some question"
    end

    test "create_chat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = App.create_chat(@invalid_attrs)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      update_attrs = %{answer: "some updated answer", question: "some updated question"}

      assert {:ok, %Chat{} = chat} = App.update_chat(chat, update_attrs)
      assert chat.answer == "some updated answer"
      assert chat.question == "some updated question"
    end

    test "update_chat/2 with invalid data returns error changeset" do
      chat = chat_fixture()
      assert {:error, %Ecto.Changeset{}} = App.update_chat(chat, @invalid_attrs)
      assert chat == App.get_chat!(chat.id)
    end

    test "delete_chat/1 deletes the chat" do
      chat = chat_fixture()
      assert {:ok, %Chat{}} = App.delete_chat(chat)
      assert_raise Ecto.NoResultsError, fn -> App.get_chat!(chat.id) end
    end

    test "change_chat/1 returns a chat changeset" do
      chat = chat_fixture()
      assert %Ecto.Changeset{} = App.change_chat(chat)
    end
  end
end
