defmodule ChatGPTWeb.PageController do
  use ChatGPTWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
