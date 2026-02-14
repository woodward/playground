defmodule PlaygroundWeb.DemoLive do
  use PlaygroundWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_id: 4,
       users: [
         %{id: 1, first_name: "Jose", last_name: "Valim", badge: "success"},
         %{id: 2, first_name: "Chris", last_name: "McCord", badge: "success"},
         %{id: 3, first_name: "Jose", last_name: "Valim", badge: "error"},
         %{id: 4, first_name: "Chris", last_name: "McCord", badge: "warning"}
       ]
     )}
  end

  @impl Phoenix.LiveView
  def handle_event("save_user", %{"user" => params}, socket) do
    user = %{
      first_name: params["first_name"],
      last_name: params["last_name"],
      badge: "success",
      id: socket.assigns.current_id + 1
    }

    {:noreply,
     socket
     |> update(:users, &(&1 ++ [user]))
     |> update(:current_id, &(&1 + 1))}
  end
end
