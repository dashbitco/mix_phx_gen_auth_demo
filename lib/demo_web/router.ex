defmodule DemoWeb.Router do
  use DemoWeb, :router

  import DemoWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # NOTE: we may have to ask the user to do this one manually :/
    plug :authenticate_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DemoWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", DemoWeb do
  #   pipe_through :api
  # end

  ## New routes

  scope "/", DemoWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/login", UserSessionController, :new
    post "/users/login", UserSessionController, :create
  end

  scope "/", DemoWeb do
    pipe_through [:browser, :require_authenticated_user]

    delete "/users/logout", UserSessionController, :delete
  end

  scope "/", DemoWeb do
    pipe_through [:browser]

    get "/users/confirm/new", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
