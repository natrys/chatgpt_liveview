defmodule ChatGPTWeb.Chat do
  use ChatGPTWeb, :live_component

  def mount(socket) do
    {:ok, stream(socket, :history, [])}
  end

  def update(%{chat: chat}, socket) do
    socket =
      if chat do
        stream_insert(socket, :history, chat)
      else
        socket
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="pl-4 pt-2 flex flex-col w-full">
      <div
        class="flex flex-col prose prose-md max-w-none flex-none h-[90vh] overflow-y-scroll px-2 mb-2 space-y-10"
        id="chat-history"
        phx-update="stream"
        phx-hook="HandleChatUpdate"
      >
        <%= for {dom_id, conversation} <- @streams.history do %>
          <div id={dom_id}>
            <ChatGPTWeb.HelperComponent.format_conversation conversation={conversation} />
          </div>
        <% end %>
      </div>

      <textarea
        class="border-2 border-gray-300 dark:border-gray-600 rounded w-full h-full bg-gray-100 dark:bg-gray-700 disabled:bg-gray-300 disabled:text-gray-500 disabled:ring-0 disabled:border-gray-300 mb-2"
        placeholder="Talk to ChatGPT (Alt+Enter to start new session, Shift+Enter to maintain old session)"
        id="question-textarea"
        phx-hook="HandleQuestion"
      ></textarea>
    </div>
    """
  end
end

defmodule ChatGPTWeb.Search do
  use ChatGPTWeb, :live_component

  def fetch_history(last) do
    ChatGPT.App.list_last_chats(5, last)
  end

  def mount(socket) do
    socket =
      socket
      |> assign(last_id: 0)
      |> stream(:history_batches, [])

    {:ok, load_more(socket)}
  end

  def load_more(socket) do
    last_id = socket.assigns.last_id
    new_chats = fetch_history(last_id)

    if length(new_chats) == 0 do
      socket
      |> put_flash(:info, "Reached end of history")
    else
      socket
      |> stream_insert(:history_batches, %{id: last_id, chats: new_chats}, at: 0)
      |> assign(last_id: List.first(new_chats).id)
    end
  end

  def handle_event("search-load-more", _params, socket) do
    {:noreply, load_more(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-screen pt-4">
      <.flash kind={:info} flash={@flash} title="Notification" />
      <form phx-submit="search-submit" class="mx-auto md:w-1/2">
        <input
          type="text"
          class="rounded-full text-center border-zinc-300 placeholder:text-gray-400 w-full"
          placeholder="History Search"
          phx-submit="search-submit"
        />
        <button></button>
      </form>

      <div class="flex justify-center mx-auto pt-4">
        <button
          class="px-1 py-1 text-xs text-slate-500 border-gray-200 border-2 rounded flex items-center bg-gray-50 hover:bg-gray-100 text-gray-700"
          phx-click="search-load-more"
          phx-target={@myself}
        >
          <.icon name="hero-arrow-path" class="w-4 h-4" />
          <span>Load Older</span>
        </button>
      </div>

      <div
        class="mt-2 flex flex-col w-full overflow-y-scroll"
        id="search-history"
        phx-update="stream"
      >
        <%= for {dom_id, batch} <- @streams.history_batches do %>
          <div id={dom_id}>
            <%= for record <- batch.chats do %>
              <div class="border-gray-200 rounded m-4 p-4 shadow">
                <ChatGPTWeb.HelperComponent.format_conversation conversation={record} />
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
