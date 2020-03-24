defmodule Demo.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both e-mail and password.
  Otherwise databases may truncate them without warnings, which could
  lead to unpredictable or insecure behaviour. Long passwords may also
  be very expensive to encrypt.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Demo.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    |> maybe_encrypt_password()
  end

  defp maybe_encrypt_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      put_change(changeset, :encrypted_password, Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the e-mail.

  It requires the e-mail to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password)
    |> validate_password()
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  Returns the given user if valid,

  If there is no user or the user doesn't have a password,
  we encrypt a blank password to avoid timing attacks.
  """
  def valid_password?(%Demo.Accounts.User{encrypted_password: encrypted_password}, password)
      when is_binary(encrypted_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, encrypted_password)
  end

  def valid_password?(_, _) do
    Bcrypt.hash_pwd_salt("unused hash to avoid timing attacks")
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
