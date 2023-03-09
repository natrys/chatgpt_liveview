defmodule ChatgptWeb.PageController do
  use ChatgptWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
