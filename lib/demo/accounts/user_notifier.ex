defmodule Demo.Accounts.UserNotifier do
  # For simplicity, this module simply prints messages to the terminal.
  # You should replace it by a proper e-mail or notification tool, such as:
  #
  #   * Swoosh - https://github.com/swoosh/swoosh
  #   * Bamboo - https://github.com/thoughtbot/bamboo
  #
  def deliver_confirmation_instructions(user, url) do
    IO.puts """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the url below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """
  end
end
