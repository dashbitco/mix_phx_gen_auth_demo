defmodule Demo.AccountsFixtures do
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Demo.Accounts.register_user()

    user
  end

  def capture_user_token(fun) do
    captured =
      ExUnit.CaptureLog.capture_log(fn ->
        fun.(&"[TOKEN]#{&1}[TOKEN]")
      end)

    [_, token, _] = String.split(captured, "[TOKEN]")
    token
  end
end
