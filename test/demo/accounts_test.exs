defmodule Demo.AccountsTest do
  use Demo.DataCase

  alias Demo.Accounts
  alias Demo.Accounts.User

  @valid_password "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      %{
        email: "user#{System.unique_integer()}@example.com",
        password: @valid_password
      }
      |> Map.merge(Map.new(attrs))
      |> Accounts.register_user()

    user
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_nad_password/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email_and_password(user.email, @valid_password)
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(123)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for e-mail and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates e-mail uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with an encrypted password" do
      email = "user#{System.unique_integer()}@example.com"
      {:ok, user} = Accounts.register_user(%{email: email, password: @valid_password})
      assert user.email == email
      assert is_binary(user.encrypted_password)
      assert is_nil(user.confirmed_at)
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, @valid_password, %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, @valid_password, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for e-mail and password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.apply_user_email(user, @valid_password, %{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates e-mail uniqueness", %{user: user} do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.apply_user_email(user, @valid_password, %{email: email})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      email = "user#{System.unique_integer()}@example.com"
      {:error, changeset} = Accounts.apply_user_email(user, "invalid", %{email: email})
      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the e-mail without persisting it", %{user: user} do
      email = "user#{System.unique_integer()}@example.com"
      {:ok, user} = Accounts.apply_user_email(user, @valid_password, %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end
end
