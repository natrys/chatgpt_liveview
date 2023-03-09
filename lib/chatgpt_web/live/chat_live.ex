defmodule ChatgptWeb.ChatLive do
  use ChatgptWeb, :live_view

  def mount(_param, _session, socket) do
    socket =
      socket
      |> assign(
        temperature: 0.4,
        maximum_length: 2000,
        frequency_penalty: 0.0,
        presence_penalty: 0.5
      )
      |> stream(:history, [])

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

  def handle_event("question-submit", question, socket) do
    answer = Chatgpt.API.request(%{
      temperature: socket.assigns.temperature,
      frequency_penalty: socket.assigns.frequency_penalty,
      presence_penalty: socket.assigns.presence_penalty,
      message: question
    })

    socket =
      socket
      |> stream_insert(:history, %{id: :rand.uniform(1000000000), question: question, answer: answer})

    {:noreply, push_event(socket, "clear-question", %{})}
  end
end
