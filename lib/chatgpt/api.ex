defmodule Chatgpt.API do
  @system """
  Be succinct and to the point. Don't use filler words. Assume you are talking to a competent person.
  """

  def get_api_key do
    Application.fetch_env!(:chatgpt, :api_key)
  end

  def craft_body(config) do
    Jason.encode_to_iodata(%{
      "model" => "gpt-3.5-turbo",
      "temperature" => config.temperature,
      "max_tokens" => 1024,
      "frequency_penalty" => config.frequency_penalty,
      "presence_penalty" => config.presence_penalty,
      "messages" => [
        %{"role" => "system", "content" => @system},
        %{"role" => "user", "content" => config.message}
      ]
    })
  end

  def make_request(body) do
    Finch.build(
      :post,
      "https://api.openai.com/v1/chat/completions",
      [{"Authorization", "Bearer #{get_api_key()}"}, {"Content-Type", "application/json"}],
      body
    )
    |> Finch.request(Chatgpt.Finch, receive_timeout: 20_000)
  end

  def request(config) do
    with {:ok, body} <- craft_body(config),
         {:ok, response} <- make_request(body) do
      response.body
      |> Jason.decode()
      |> then(fn {:ok, resp} -> Map.get(resp, "choices") end)
      |> hd()
      |> Map.get("message")
      |> Map.get("content")
      |> String.trim()
    end
  end
end
