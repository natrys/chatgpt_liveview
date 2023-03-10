defmodule ChatGPTWeb.ChatLogic do
  use ChatGPTWeb, :live_component

  def update(_assign, socket) do
    socket =
      socket
      |> assign(
        temperature: 0.4,
        maximum_length: 2000,
        frequency_penalty: 0.0,
        presence_penalty: 0.5,
        last_id: nil,
        session: []
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

  def handle_event("question-submit", params, socket) do
    %{"question" => question, "session" => _session} = params

    answer =
      ChatGPT.API.request(%{
        temperature: socket.assigns.temperature,
        frequency_penalty: socket.assigns.frequency_penalty,
        presence_penalty: socket.assigns.presence_penalty,
        message: question
      })

    new_chat = %{
      id: :rand.uniform(1_000_000_000),
      question: question,
      answer: answer
    }

    send(self(), {:new_chat, new_chat})

    {:noreply, push_event(socket, "clear-question", %{})}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col px-2" id="chat-logic">
      <span class="text-center text-xl underline">Model Settings</span>

      <ChatGPTWeb.HelperComponent.slider_label value={@temperature} title="Temperature" />
      <ChatGPTWeb.HelperComponent.slider
        value={@temperature}
        event="update-temperature"
        range="0:2"
        target={@myself}
      />

      <ChatGPTWeb.HelperComponent.slider_label value={@frequency_penalty} title="Frequency Penalty" />
      <ChatGPTWeb.HelperComponent.slider
        value={@frequency_penalty}
        event="update-fpen"
        range="-2:2"
        target={@myself}
      />

      <ChatGPTWeb.HelperComponent.slider_label value={@presence_penalty} title="Presence Penalty" />
      <ChatGPTWeb.HelperComponent.slider
        value={@presence_penalty}
        event="update-ppen"
        range="-2:2"
        target={@myself}
      />
    </div>
    """
  end
end
