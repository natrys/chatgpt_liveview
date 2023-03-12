defmodule ChatGPTWeb.ChatLive do
  use ChatGPTWeb, :live_view

  def mount(_param, _session, socket) do
    {:ok, assign(socket, theme: "light")}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, mode: socket.assigns.live_action)}
  end

  def handle_info({:new_chat, new_chat}, socket) do
    send_update(ChatGPTWeb.Chat, id: "chat-component", chat: new_chat)
    {:noreply, socket}
  end

  def handle_event("toggle-theme", _params, socket) do
    theme = if socket.assigns.theme == "light", do: "dark", else: "light"
    {:noreply, assign(socket, theme: theme)}
  end
end
