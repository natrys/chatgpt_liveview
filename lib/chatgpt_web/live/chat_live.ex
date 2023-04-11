defmodule ChatGPTWeb.ChatLive do
  use ChatGPTWeb, :live_view

  def mount(_param, _session, socket) do
    {:ok, assign(socket, theme: "winter")}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, mode: socket.assigns.live_action)}
  end

  def handle_event("toggle-theme", _params, socket) do
    theme = if socket.assigns.theme == "winter", do: "dark", else: "winter"
    {:noreply, assign(socket, theme: theme)}
  end

  def handle_info({ref, context}, socket) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    socket =
      with(
        {:ok, answer} <- context.response,
        {:ok, new_chat} <-
          if context.save_chat do
            ChatGPT.App.create_chat(%{
              question: context.question,
              answer: answer,
              parent_id: if(context.session, do: context.last_id, else: nil)
            })
          else
            {:ok,
             %{
               id: Enum.random(1_000_000..2_000_000),
               question: context.question,
               answer: answer,
               parent_id: nil
             }}
          end
      ) do
        send_update(ChatGPTWeb.Chat, id: "chat-component", chat: new_chat)

        send_update(ChatGPTWeb.ChatLogic,
          id: "chat-logic",
          last_id: if(context.save_chat, do: new_chat.id, else: nil)
        )

        socket
      else
        {:error, _} ->
          socket
          |> push_event("unfreeze-question-textarea", %{})
          |> put_flash(:error, "ChatGPT API didn't respond in time.")
      end

    {:noreply, socket}
  end
end
