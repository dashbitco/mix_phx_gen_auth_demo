defmodule DemoWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Must be invoked every time after sign in.

  It deletes the CSRF token and renews the session
  to avoid fixation attacks.
  """
  def sign_in(conn, user) do
    Plug.CSRFProtection.delete_csrf_token()

    conn
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end
end
