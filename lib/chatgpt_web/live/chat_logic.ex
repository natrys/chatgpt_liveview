defmodule ChatGPTWeb.ChatLogic do
  @system "You are succinct and to the point. You don't use filler words. You assume that you are talking to a competent person. You prefer showing off technical terms and jargons over simpler explanations. You prefer using programming language over natural language."

  use ChatGPTWeb, :live_component

  def mount(socket) do
    socket =
      socket
      |> assign(
        temperature: 0.4,
        frequency_penalty: 0.0,
        presence_penalty: 0.5,
        system: @system,
        system_edit: false,
        system_form: nil,
        last_id: nil,
        session: false,
        save_chat: true
      )

    {:ok, socket}
  end

  def handle_event("update-temperature", %{"value" => value}, socket) do
    {value, _} = Float.parse(value)
    {:noreply, assign(socket, temperature: value)}
  end

  def handle_event("update-fpen", %{"value" => value}, socket) do
    {value, _} = Float.parse(value)
    {:noreply, assign(socket, frequency_penalty: value)}
  end

  def handle_event("update-ppen", %{"value" => value}, socket) do
    {value, _} = Float.parse(value)
    {:noreply, assign(socket, presence_penalty: value)}
  end

  def handle_event("toggle-system-edit", %{"status" => status}, socket) do
    system_edit = status == "on"
    system = socket.assigns.system
    {:noreply, assign(socket, system_edit: system_edit, system_form: %{"system" => system})}
  end

  def handle_event("system-submit", %{"system" => system}, socket) do
    {:noreply, assign(socket, system: String.trim(system), system_edit: false, system_form: nil)}
  end

  def handle_event("toggle-save-chat", %{"value" => "true"}, socket),
    do: {:noreply, assign(socket, save_chat: true)}

  def handle_event("toggle-save-chat", _, socket) do
    socket =
      socket
      |> assign(save_chat: false)
      |> put_flash(:info, "Session feature will be disabled if chat saving is not allowed.")

    {:noreply, socket}
  end

  def handle_event("question-submit", params, socket) do
    %{"question" => question, "session" => session} = params

    socket =
      if session and not socket.assigns.save_chat do
        socket
        |> put_flash(:error, "Can't maintain session, unless chat is being saved.")
        |> push_event("unfreeze-question-textarea", %{})
      else
        queue_question(socket.assigns, question, session)
        socket
      end

    {:noreply, socket}
  end

  def queue_question(assigns, question, session) do
    history =
      if session and assigns.last_id do
        ChatGPT.App.get_chat_ancestors!(assigns.last_id)
        |> ChatGPT.App.get_chat_by_ids!()
        |> Enum.reduce(
          [%{"role" => "user", "content" => question}],
          fn [question, answer], acc ->
            [
              %{"role" => "user", "content" => question}
              | [%{"role" => "assistant", "content" => answer} | acc]
            ]
          end
        )
      else
        [%{"role" => "user", "content" => question}]
      end

    messages = [%{"role" => "system", "content" => assigns.system} | history]

    question_config =
      assigns
      |> Map.split([
        :temperature,
        :frequency_penalty,
        :presence_penalty,
      ])
      |> elem(0)
      |> Map.merge(%{messages: messages})

    answer_config = %{
      last_id: assigns.last_id,
      save_chat: assigns.save_chat,
      session: session,
      question: question
    }

    Task.async(fn ->
      #Process.sleep(2_000)
      question_config
      |> Map.put(:messages, messages)
      #|> then(fn _context -> {:ok, String.upcase(question)} end)
      |> ChatGPT.API.request()
      |> then(&%{response: &1})
      |> Map.merge(answer_config)
    end)
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col pr-2 lg:pr-4" id="chat-logic">
      <.flash id="error-flash" kind={:info} flash={@flash} title="Notification" phx-target={@myself} />
      <.flash id="info-flash" kind={:error} flash={@flash} title="Error" phx-target={@myself} />
      <.modal
        :if={@system_edit}
        id="system-modal"
        show
        on_cancel={JS.push("toggle-system-edit", target: "#chat-logic", value: %{"status" => "off"})}
      >
        <.form for={@system_form} phx-submit="system-submit" phx-target={@myself}>
          <.input
            name={:system}
            value={@system_form["system"]}
            type="textarea"
            class="border-2 outline-0 text-blue-400 font-mono"
          >
          </.input>
          <div class="flex justify-center mt-4 mx-auto">
            <button class="px-2 py-2 bg-zinc-300 hover:bg-zinc-400 text-sm rounded shadow">
              Set
            </button>
          </div>
        </.form>
      </.modal>

      <span class="text-center text-xl underline">Model Settings</span>
      <div class="flex gap-2 items-center mt-16 mb-1">
        <span
          class="tooltip hidden lg:block"
          data-tip="What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
        <ChatGPTWeb.HelperComponent.slider_label value={@temperature} title="Temperature" />
      </div>
      <ChatGPTWeb.HelperComponent.slider
        value={@temperature}
        event="update-temperature"
        range="0:2"
        target={@myself}
      />

      <div class="inline-flex gap-2 items-center mt-8 mb-1">
        <span
          class="tooltip hidden lg:block"
          data-tip="Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
        <ChatGPTWeb.HelperComponent.slider_label value={@frequency_penalty} title="Frequency Penalty" />
      </div>
      <ChatGPTWeb.HelperComponent.slider
        value={@frequency_penalty}
        event="update-fpen"
        range="-2:2"
        target={@myself}
      />

      <div class="inline-flex gap-2 items-center mt-8 mb-1">
        <span
          class="tooltip hidden lg:block"
          data-tip="Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
        <ChatGPTWeb.HelperComponent.slider_label value={@presence_penalty} title="Presence Penalty" />
      </div>
      <ChatGPTWeb.HelperComponent.slider
        value={@presence_penalty}
        event="update-ppen"
        range="-2:2"
        target={@myself}
      />
      <div
        class="inline-flex items-center mt-8 gap-2 cursor-pointer"
        phx-click="toggle-system-edit"
        phx-value-status="on"
        phx-target={@myself}
      >
        <span class="underline">Personality</span>
        <.icon name="hero-pencil-square" class="w-8 h-8" />
      </div>
      <div class="inline-flex items-center mt-8 gap-2 cursor-pointer">
        <span class="underline">Save Chat</span>
        <input
          type="checkbox"
          name="save-chat"
          class="checkbox dark:bg-gray-400"
          checked={@save_chat}
          value="true"
          phx-click="toggle-save-chat"
          phx-target={@myself}
        />
      </div>
    </div>
    """
  end
end
