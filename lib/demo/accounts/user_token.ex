defmodule Demo.Accounts.UserToken do
  use Ecto.Schema
  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  schema "user_tokens" do
    field :hashed_token, :binary
    field :context, :string
    field :sent_to, :string
    belongs_to :user, Demo.Accounts.User

    timestamps(updated_at: false)
  end

  def confirmation_token(user) do
    emailable_token(user, "confirm", user.email)
  end

  def confirmation_query(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from token in Demo.Accounts.UserToken,
            join: user in assoc(token, :user),
            where:
              token.hashed_token == ^hashed_token and
                token.context == "confirm" and
                token.inserted_at > ago(1, "week") and
                token.sent_to == user.email,
            select: {token, user}

        {:ok, query}

      :error ->
        :error
    end
  end

  defp emailable_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %Demo.Accounts.UserToken{
       hashed_token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end
end
