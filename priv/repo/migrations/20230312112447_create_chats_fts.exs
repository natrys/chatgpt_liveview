defmodule ChatGPT.Repo.Migrations.CreateChatsFts do
  use Ecto.Migration

  def up do
    execute("""
      CREATE VIRTUAL TABLE chats_fts USING fts5 (
        updated_at UNINDEXED,
        inserted_at UNINDEXED,
        parent_id UNINDEXED,

        question,
        answer,

        tokenize="trigram"
      );
      """
    )

    execute("INSERT INTO chats_fts(question, answer) SELECT question, answer FROM chats;")

    execute("""
      CREATE TRIGGER chats_fts_insert AFTER INSERT ON chats
      BEGIN
        INSERT INTO chats_fts(question, answer) VALUES (NEW.question, NEW.answer);
      END;
      """
    )
  end

  def down do
    execute("""
      DROP TABLE chats_fts;
      """
    )
  end
end
