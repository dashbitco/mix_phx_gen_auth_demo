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

  @doc false
  # It is important to validate the length of both e-mail and password.
  # Otherwise databases may truncate them without warnings, which could
  # lead to unpredictable or insecure behaviour. Long passwords may also
  # be very expensive to encrypt.
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, "@")
    |> validate_length(:email, max: 160)
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
end
