defmodule EventosWeb.UserController do
  use EventosWeb, :controller
  import Logger

  alias Eventos.Accounts
  alias Eventos.Accounts.User

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end

  def register(conn, %{"email" => email, "password" => password, "username" => username}) do

    {:ok, {privkey, pubkey}} = RsaEx.generate_keypair("4096")
    account_change = Ecto.Changeset.change(%Eventos.Accounts.Account{}, %{
      username: username,
      description: "tata",
      display_name: "toto",
      domain: nil,
      private_key: privkey,
      public_key: pubkey,
      uri: "",
      url: ""
    })

    user_change = Eventos.Accounts.User.registration_changeset(%Eventos.Accounts.User{}, %{
      email: email,
      password: password,
      password_confirmation: password
    })

    account_with_user = Ecto.Changeset.put_assoc(account_change, :user, user_change)

    Eventos.Repo.insert!(account_with_user)

    user = Eventos.Accounts.find(email)
    user = Eventos.Repo.preload user, :account

    render conn, "user.json", %{user: user}
  end
end
