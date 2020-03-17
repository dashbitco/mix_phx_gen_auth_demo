defmodule Demo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Demo.Repo
  alias Demo.Accounts.{User, UserToken, UserNotifier}

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_emai("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def registration_user(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  @doc """
  Generates a session/cookie token.
  """
  def generate_to_be_signed_token(user, context) do
    {token, user_token} = UserToken.build_to_be_signed_token(user, context)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_signed_token(token, context) do
    {:ok, query} = UserToken.verify_to_be_signed_token_query(token, context)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_signed_token(token, context) do
    Repo.delete_all(UserToken.token_and_context_query(token, context))
    :ok
  end

  @doc """
  Delivers the confirmation e-mail instructions to the given user.

  ## Examples

      iex> deliver_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm))
      :ok

      iex> deliver_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm))
      {:error, :already_confirmed}

  """
  def deliver_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_user_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
      :ok
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_user_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, _} <- Repo.transaction(confirmation_multi(user)) do
      :ok
    else
      _ -> :error
    end
  end

  defp confirmation_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:user_tokens, UserToken.delete_all_tokens_query(user, "confirm"))
  end
end
