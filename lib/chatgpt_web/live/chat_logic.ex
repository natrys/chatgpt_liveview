defmodule ChatGPTWeb.ChatLogic do
  @system "Be succinct and to the point. Don't use filler words. Assume you are talking to a competent person."

  use ChatGPTWeb, :live_component

  def update(_assign, socket) do
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
        session: false
      )

    {:ok, socket}
  end

  def handle_event("update-temperature", %{"value" => value}, socket) do
    {:noreply, assign(socket, temperature: String.to_float(value))}
  end

  def handle_event("update-fpen", %{"value" => value}, socket) do
    {:noreply, assign(socket, frequency_penalty: String.to_float(value))}
  end

  def handle_event("update-ppen", %{"value" => value}, socket) do
    {:noreply, assign(socket, presence_penalty: String.to_float(value))}
  end

  def handle_event("toggle-system-edit", %{"status" => status}, socket) do
    system_edit = status == "on"
    system = socket.assigns.system
    {:noreply, assign(socket, system_edit: system_edit, system_form: %{"system" => system})}
  end

  def handle_event("system-submit", %{"system" => system}, socket) do
    {:noreply, assign(socket, system: String.trim(system), system_edit: false, system_form: nil)}
  end

  def handle_event("question-submit", params, socket) do
    %{"question" => question, "session" => session} = params
    last_id = socket.assigns.last_id

    history =
      if session and last_id do
        ChatGPT.App.get_chat_ancestors!(socket.assigns.last_id)
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

    messages = [%{"role" => "system", "content" => socket.assigns.system} | history]

    answer =
      ChatGPT.API.request(%{
        temperature: socket.assigns.temperature,
        frequency_penalty: socket.assigns.frequency_penalty,
        presence_penalty: socket.assigns.presence_penalty,
        messages: messages
      })
    #answer = String.upcase(question)

    {:ok, new_chat} =
      ChatGPT.App.create_chat(%{
        question: question,
        answer: answer,
        parent_id: if(session, do: socket.assigns.last_id, else: nil)
      })

    send(self(), {:new_chat, new_chat})

    {:noreply, assign(socket, last_id: new_chat.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col px-2" id="chat-logic">
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
            <button class="px-2 py-2 bg-zinc-300 hover:bg-zinc-400 text-sm rounded shadow">Set</button>
          </div>
        </.form>
      </.modal>
      <span class="text-center text-xl underline">Model Settings</span>

      <div class="flex gap-2 items-center mt-16 mb-1">
        <ChatGPTWeb.HelperComponent.slider_label value={@temperature} title="Temperature" />
        <span
          class="tooltip tooltip-top"
          data-tip="What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
      </div>
      <ChatGPTWeb.HelperComponent.slider
        value={@temperature}
        event="update-temperature"
        range="0:2"
        target={@myself}
      />

      <div class="inline-flex gap-2 items-center mt-8 mb-1">
        <ChatGPTWeb.HelperComponent.slider_label value={@frequency_penalty} title="Frequency Penalty" />
        <span
          class="tooltip"
          data-tip="Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
      </div>
      <ChatGPTWeb.HelperComponent.slider
        value={@frequency_penalty}
        event="update-fpen"
        range="-2:2"
        target={@myself}
      />

      <div class="inline-flex gap-2 items-center mt-8 mb-1">
        <ChatGPTWeb.HelperComponent.slider_label value={@presence_penalty} title="Presence Penalty" />
        <span
          class="tooltip"
          data-tip="Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics."
        >
          <.icon name="hero-information-circle" class="w-6 h-6" />
        </span>
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
    </div>
    """
  end
end
