defmodule DemoWeb.UserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias Demo.Accounts
  alias DemoWeb.Router.Helpers, as: Routes

  @doc """
  Logs the user in.

  It deletes the CSRF token and renews the session
  to avoid fixation attacks.
  """
  def login_user(conn, user) do
    Plug.CSRFProtection.delete_csrf_token()
    token = Accounts.generate_to_be_signed_token(user, "session")

    user_return_to = get_session(conn, :user_return_to)
    delete_session(conn, :user_return_to)

    conn
    |> put_session(:user_token, token)
    |> configure_session(renew: true)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. If you want to keep
  some data in the session, we recommend you to manually copy
  the data you want to maintain.
  """
  def logout_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_signed_token(user_token, "session")

    conn
    |> clear_session()
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  def authenticate_user(conn, _opts) do
    user_token = get_session(conn, :user_token)
    user = user_token && Accounts.get_user_by_signed_token(user_token, "session")
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
      |> put_flash(:error, "You must be authenticated to access this page.")
      |> put_session(:user_return_to, conn.request_path)
      |> redirect(to: Routes.user_session_path(conn, :new))
      |> halt()
    end
  end

  defp signed_in_path(_conn), do: "/"
end
