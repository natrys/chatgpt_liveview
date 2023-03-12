defmodule ChatGPTWeb.HelperComponent do
  use Phoenix.Component

  attr :event, :string, required: true
  attr :range, :string, required: true
  attr :value, :float, required: true
  attr :target, :atom, required: true

  def slider(assigns) do
    [val_min, val_max] = String.split(assigns.range, ":")
    assigns = assign(assigns, val_min: val_min, val_max: val_max)

    ~H"""
    <input
      type="range"
      min={@val_min}
      max={@val_max}
      step="0.01"
      value={@value}
      phx-click={@event}
      phx-target={@target}
      class="range range-xs"
    />
    """
  end

  attr :title, :string, required: true
  attr :value, :float, required: true

  def slider_label(assigns) do
    ~H"""
    <%= @title %>: <span class="font-bold"><%= @value %></span>
    """
  end

  def format_conversation(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 font-['Finlandica'] text-lg text-black dark:text-gray-50">
      <div class="p-2 bg-purple-50 dark:bg-zinc-700 rounded flex items-center">
        <span class="w-10 text-left">Q</span>
        <div class="whitespace-pre-wrap"><%= @conversation.question %></div>
      </div>
      <div class="p-4 bg-gray-50 dark:bg-gray-700 rounded flex items-center leading-tight ml-10">
        <div class="whitespace-pre-wrap"><%= @conversation.answer %></div>
      </div>
    </div>
    """
  end
end
