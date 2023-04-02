defmodule ChatGPT.App do
  @moduledoc """
  The App context.
  """

  import Ecto.Query, warn: false
  alias ChatGPT.Repo

  alias ChatGPT.App.Chat
  alias ChatGPT.App.ChatFTS

  @doc """
  Returns the list of chats.

  ## Examples

      iex> list_chats()
      [%Chat{}, ...]

  """
  def list_chats do
    Repo.all(Chat)
  end

  def list_last_chats(last \\ 0) do
    from(c in Chat, order_by: {:desc, c.id}, limit: 5)
    |> then(fn query ->
      if last > 0 do
        from(c in query, where: c.id < ^last)
      else
        query
      end
    end)
    |> Repo.all()
    |> Enum.sort(fn a, b -> a.id < b.id end)
  end

  def search_chats(q) do
    from(c in ChatFTS,
      select: [:id, :question, :answer],
      where: fragment("rank NOT NULL AND (question MATCH ? OR answer MATCH ?)", ^q, ^q),
      order_by: [asc: :rank],
      limit: 20
    )
    |> Repo.all()
  end

  @doc """
  Gets a single chat.

  Raises `Ecto.NoResultsError` if the Chat does not exist.

  ## Examples

      iex> get_chat!(123)
      %Chat{}

      iex> get_chat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat!(id), do: Repo.get!(Chat, id)

  def get_chat_ancestors!(id) do
    query = """
      WITH RECURSIVE cte(id, parent_id) AS (
        SELECT id, parent_id FROM chats WHERE id = $1
        UNION ALL
        SELECT c2.id, c2.parent_id FROM cte c1
        INNER JOIN chats c2 ON c1.parent_id = c2.id
      )
      SELECT id FROM cte;
    """

    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query, [id])

    result.rows
    |> List.flatten()
  end

  def get_chat_by_ids!(ids) do
    from(c in Chat, select: [c.question, c.answer], where: c.id in ^ids, order_by: {:desc, c.id})
    |> Repo.all()
  end

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat(attrs \\ %{}) do
    %Chat{}
    |> Chat.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat.

  ## Examples

      iex> update_chat(chat, %{field: new_value})
      {:ok, %Chat{}}

      iex> update_chat(chat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat(%Chat{} = chat, attrs) do
    chat
    |> Chat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat.

  ## Examples

      iex> delete_chat(chat)
      {:ok, %Chat{}}

      iex> delete_chat(chat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat(%Chat{} = chat) do
    Repo.delete(chat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.

  ## Examples

      iex> change_chat(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  def change_chat(%Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs)
  end
end
