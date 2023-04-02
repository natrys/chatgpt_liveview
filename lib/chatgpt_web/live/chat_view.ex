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
    <div class="pl-2 lg:pl-4 pt-2 flex flex-col max-h-screen w-full pb-2 gap-2">
      <div
        class="flex flex-col prose prose-md max-w-none flex-none h-[90%] overflow-y-scroll gap-10"
        id="chat-history"
        phx-update="stream"
        phx-hook="HandleChatUpdate"
      >
        <div :for={{dom_id, conversation} <- @streams.history} id={dom_id}>
          <ChatGPTWeb.HelperComponent.format_conversation conversation={conversation} />
        </div>
      </div>

      <textarea
        class="border-2 border-gray-300 dark:border-gray-600 rounded w-full h-full bg-stone-50 dark:bg-gray-700 disabled:bg-stone-200 disabled:text-gray-500 disabled:ring-0 disabled:border-stone-300"
        placeholder="Talk to ChatGPT (Alt+Enter to start new session, Shift+Enter to maintain old session)"
        id="question-textarea"
        phx-hook="HandleQuestion"
        autofocus
      ></textarea>
    </div>
    """
  end
end

defmodule ChatGPTWeb.Search do
  use ChatGPTWeb, :live_component

  def fetch_history(last, search_for) do
    if search_for == "" do
      ChatGPT.App.list_last_chats(last)
    else
      ChatGPT.App.search_chats(search_for)
    end
  end

  def mount(socket) do
    socket =
      socket
      |> assign(last_id: 0)
      |> assign(search_for: "")
      |> stream(:history_batches, [])

    {:ok, load_more(socket)}
  end

  def load_more(socket) do
    last_id = socket.assigns.last_id
    search_for = socket.assigns.search_for
    new_chats = fetch_history(last_id, search_for)

    if length(new_chats) == 0 do
      socket
      |> put_flash(:info, "No result found or reached end of history")
    else
      socket
      |> stream_insert(:history_batches, %{id: last_id, chats: new_chats}, at: 0)
      |> assign(last_id: List.first(new_chats).id)
    end
  end

  def handle_event("search-load-more", _params, socket) do
    {:noreply, load_more(socket)}
  end

  def handle_event("search-submit", %{"search_for" => search_for}, socket) do
    socket = assign(socket, search_for: search_for, last_id: 0)

    socket = if search_for != "" do
      socket
      |> stream_delete_by_dom_id(:history_batches, socket.assigns.last_id)
    else
      socket
    end

    {:noreply, load_more(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full max-h-screen mt-4">
      <.flash kind={:info} flash={@flash} title="Notification" phx-target={@myself} />
      <.flash kind={:error} flash={@flash} title="Notification" phx-target={@myself} />
      <form phx-submit="search-submit" phx-target={@myself} class="mx-auto md:w-1/2" autofocus>
        <input
          type="text"
          name="search_for"
          id="search-history-input"
          class="rounded-full text-center border-zinc-300 placeholder:text-gray-400 w-full"
          placeholder="History Search"
          phx-submit="search-submit"
          autofocus
        />
        <button class="hidden"></button>
      </form>

      <div :if={@search_for == ""} class="flex justify-center mx-auto mt-4">
        <button
          class="px-1 py-1 text-xs text-slate-500 border-gray-100 border-2 rounded flex items-center bg-gray-50 hover:bg-gray-100 text-gray-700 gap-2"
          phx-click="search-load-more"
          phx-target={@myself}
        >
          <.icon name="hero-arrow-path" class="w-4 h-4" />
          <span>Older</span>
        </button>
      </div>

      <div
        class="mt-2 flex flex-col w-full overflow-y-scroll"
        id="search-history"
        phx-update="stream"
      >
        <div :for={{dom_id, batch} <- @streams.history_batches} id={dom_id}>
          <%= for record <- batch.chats do %>
            <div class="border-gray-200 rounded m-4 p-4 shadow">
              <ChatGPTWeb.HelperComponent.format_conversation conversation={record} />
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
