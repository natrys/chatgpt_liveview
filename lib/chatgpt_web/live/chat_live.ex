defmodule ChatGPTWeb.ChatLive do
  use ChatGPTWeb, :live_view

  def mount(_param, _session, socket) do
    socket =
      socket
      |> stream(:history, [])

    {:ok, socket}
  end

  def handle_info({:new_chat, new_chat}, socket) do
    socket =
      socket
      |> stream_insert(:history, new_chat)

    {:noreply, push_event(socket, "clear-question", %{})}
  end
end
