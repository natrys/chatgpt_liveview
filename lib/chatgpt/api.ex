defmodule ChatGPT.API do
  def get_api_key do
    Application.fetch_env!(:chatgpt, :api_key)
  end

  def craft_body(config) do
    Jason.encode_to_iodata(%{
      "model" => "gpt-3.5-turbo",
      "temperature" => config.temperature,
      "frequency_penalty" => config.frequency_penalty,
      "presence_penalty" => config.presence_penalty,
      "messages" => config.messages
    })
  end

  def make_request(body) do
    Finch.build(
      :post,
      "https://api.openai.com/v1/chat/completions",
      [{"Authorization", "Bearer #{get_api_key()}"}, {"Content-Type", "application/json"}],
      body
    )
    |> Finch.request(ChatGPT.Finch, receive_timeout: 60_000)
  end

  def request(context) do
    with {:ok, body} <- craft_body(context),
         {:ok, response} <- make_request(body),
         {:ok, map} <- Jason.decode(response.body) do
      map
      |> Map.get("choices")
      |> hd()
      |> Map.get("message")
      |> Map.get("content")
      |> then(&{:ok, String.trim(&1)})
    else
      _ -> {:error, :request_error}
    end
  end
end
