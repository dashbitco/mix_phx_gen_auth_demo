defmodule DemoWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Demo.Accounts

  @doc """
  Must be invoked every time after login.

  It deletes the CSRF token and renews the session
  to avoid fixation attacks.
  """
  def login_user(conn, user) do
    Plug.CSRFProtection.delete_csrf_token()

    conn
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
    |> redirect(to: signed_in_path(conn))
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def authenticate_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && Accounts.get_user(user_id)
    assign(conn, :current_user, user)
  end

  @doc """
  Used for routes that requires the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that requires the user to be authenticated.

  If you want to enforce the user e-mail is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    end
  end

  defp signed_in_path(_conn), do: "/"
end
