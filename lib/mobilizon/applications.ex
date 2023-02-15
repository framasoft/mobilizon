defmodule Mobilizon.Applications do
  @moduledoc """
  The Applications context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Mobilizon.Applications.Application
  alias Mobilizon.Storage.Repo

  @doc """
  Returns the list of applications.

  ## Examples

      iex> list_applications()
      [%Application{}, ...]

  """
  def list_applications do
    Repo.all(Application)
  end

  @doc """
  Gets a single application.

  Raises `Ecto.NoResultsError` if the Application does not exist.

  ## Examples

      iex> get_application!(123)
      %Application{}

      iex> get_application!(456)
      ** (Ecto.NoResultsError)

  """
  def get_application!(id), do: Repo.get!(Application, id)

  @doc """
  Gets a single application.

  Returns nil if the Application does not exist.

  ## Examples

      iex> get_application_by_client_id(123)
      %Application{}

      iex> get_application_by_client_id(456)
      nil

  """
  def get_application_by_client_id(client_id), do: Repo.get_by(Application, client_id: client_id)

  @doc """
  Creates a application.

  ## Examples

      iex> create_application(%{field: value})
      {:ok, %Application{}}

      iex> create_application(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_application(attrs \\ %{}) do
    %Application{}
    |> Application.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a application.

  ## Examples

      iex> update_application(application, %{field: new_value})
      {:ok, %Application{}}

      iex> update_application(application, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_application(%Application{} = application, attrs) do
    application
    |> Application.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a application.

  ## Examples

      iex> delete_application(application)
      {:ok, %Application{}}

      iex> delete_application(application)
      {:error, %Ecto.Changeset{}}

  """
  def delete_application(%Application{} = application) do
    Repo.delete(application)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking application changes.

  ## Examples

      iex> change_application(application)
      %Ecto.Changeset{data: %Application{}}

  """
  def change_application(%Application{} = application, attrs \\ %{}) do
    Application.changeset(application, attrs)
  end

  alias Mobilizon.Applications.ApplicationToken

  @doc """
  Returns the list of application_tokens.

  ## Examples

      iex> list_application_tokens()
      [%ApplicationToken{}, ...]

  """
  def list_application_tokens do
    Repo.all(ApplicationToken)
  end

  @doc """
  Returns the list of application tokens for a given user_id
  """
  def list_application_tokens_for_user_id(user_id) do
    ApplicationToken
    |> where(user_id: ^user_id)
    |> where([at], is_nil(at.authorization_code))
    |> preload(:application)
    |> Repo.all()
  end

  @doc """
  Gets a single application_token.

  Raises `Ecto.NoResultsError` if the Application token does not exist.

  ## Examples

      iex> get_application_token!(123)
      %ApplicationToken{}

      iex> get_application_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_application_token!(id), do: Repo.get!(ApplicationToken, id)

  @doc """
  Gets a single application_token.

  ## Examples

      iex> get_application_token(123)
      %ApplicationToken{}

      iex> get_application_token(456)
      nil

  """
  def get_application_token(application_token_id),
    do: Repo.get(ApplicationToken, application_token_id)

  def get_application_token(app_id, user_id),
    do: Repo.get_by(ApplicationToken, application_id: app_id, user_id: user_id)

  def get_application_token_by_authorization_code(code),
    do: Repo.get_by(ApplicationToken, authorization_code: code)

  @doc """
  Creates a application_token.

  ## Examples

      iex> create_application_token(%{field: value})
      {:ok, %ApplicationToken{}}

      iex> create_application_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_application_token(attrs \\ %{}) do
    %ApplicationToken{}
    |> ApplicationToken.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id, :application_id])
  end

  @doc """
  Updates a application_token.

  ## Examples

      iex> update_application_token(application_token, %{field: new_value})
      {:ok, %ApplicationToken{}}

      iex> update_application_token(application_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_application_token(%ApplicationToken{} = application_token, attrs) do
    application_token
    |> ApplicationToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a application_token.

  ## Examples

      iex> delete_application_token(application_token)
      {:ok, %ApplicationToken{}}

      iex> delete_application_token(application_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_application_token(%ApplicationToken{} = application_token) do
    Repo.delete(application_token)
  end

  def revoke_application_token(%ApplicationToken{id: app_token_id} = application_token) do
    Multi.new()
    |> Multi.delete_all(
      :delete_guardian_tokens,
      from(gt in "guardian_tokens", where: gt.sub == ^"AppToken:#{app_token_id}")
    )
    |> Multi.delete(:delete_app_token, application_token)
    |> Repo.transaction()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking application_token changes.

  ## Examples

      iex> change_application_token(application_token)
      %Ecto.Changeset{data: %ApplicationToken{}}

  """
  def change_application_token(%ApplicationToken{} = application_token, attrs \\ %{}) do
    ApplicationToken.changeset(application_token, attrs)
  end
end
