defmodule Eventos.Events do
  @moduledoc """
  The Events context.
  """

  import Ecto.Query, warn: false
  alias Eventos.Repo

  alias Eventos.Events.Event

  @doc """
  Returns the list of events.

  ## Examples

      iex> list_events()
      [%Event{}, ...]

  """
  def list_events do
    Repo.all(Event)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(%{field: value})
      {:ok, %Event{}}

      iex> create_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{source: %Event{}}

  """
  def change_event(%Event{} = event) do
    Event.changeset(event, %{})
  end

  alias Eventos.Events.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{source: %Category{}}

  """
  def change_category(%Category{} = category) do
    Category.changeset(category, %{})
  end

  alias Eventos.Events.Tag

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{source: %Tag{}}

  """
  def change_tag(%Tag{} = tag) do
    Tag.changeset(tag, %{})
  end

  alias Eventos.Events.EventAccounts

  @doc """
  Returns the list of event_accounts.

  ## Examples

      iex> list_event_accounts()
      [%EventAccounts{}, ...]

  """
  def list_event_accounts do
    Repo.all(EventAccounts)
  end

  @doc """
  Gets a single event_accounts.

  Raises `Ecto.NoResultsError` if the Event accounts does not exist.

  ## Examples

      iex> get_event_accounts!(123)
      %EventAccounts{}

      iex> get_event_accounts!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_accounts!(id), do: Repo.get!(EventAccounts, id)

  @doc """
  Creates a event_accounts.

  ## Examples

      iex> create_event_accounts(%{field: value})
      {:ok, %EventAccounts{}}

      iex> create_event_accounts(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_accounts(attrs \\ %{}) do
    %EventAccounts{}
    |> EventAccounts.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_accounts.

  ## Examples

      iex> update_event_accounts(event_accounts, %{field: new_value})
      {:ok, %EventAccounts{}}

      iex> update_event_accounts(event_accounts, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_accounts(%EventAccounts{} = event_accounts, attrs) do
    event_accounts
    |> EventAccounts.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a EventAccounts.

  ## Examples

      iex> delete_event_accounts(event_accounts)
      {:ok, %EventAccounts{}}

      iex> delete_event_accounts(event_accounts)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_accounts(%EventAccounts{} = event_accounts) do
    Repo.delete(event_accounts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_accounts changes.

  ## Examples

      iex> change_event_accounts(event_accounts)
      %Ecto.Changeset{source: %EventAccounts{}}

  """
  def change_event_accounts(%EventAccounts{} = event_accounts) do
    EventAccounts.changeset(event_accounts, %{})
  end

  alias Eventos.Events.EventRequest

  @doc """
  Returns the list of event_requests.

  ## Examples

      iex> list_event_requests()
      [%EventRequest{}, ...]

  """
  def list_event_requests do
    Repo.all(EventRequest)
  end

  @doc """
  Gets a single event_request.

  Raises `Ecto.NoResultsError` if the Event request does not exist.

  ## Examples

      iex> get_event_request!(123)
      %EventRequest{}

      iex> get_event_request!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event_request!(id), do: Repo.get!(EventRequest, id)

  @doc """
  Creates a event_request.

  ## Examples

      iex> create_event_request(%{field: value})
      {:ok, %EventRequest{}}

      iex> create_event_request(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event_request(attrs \\ %{}) do
    %EventRequest{}
    |> EventRequest.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a event_request.

  ## Examples

      iex> update_event_request(event_request, %{field: new_value})
      {:ok, %EventRequest{}}

      iex> update_event_request(event_request, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event_request(%EventRequest{} = event_request, attrs) do
    event_request
    |> EventRequest.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a EventRequest.

  ## Examples

      iex> delete_event_request(event_request)
      {:ok, %EventRequest{}}

      iex> delete_event_request(event_request)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event_request(%EventRequest{} = event_request) do
    Repo.delete(event_request)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event_request changes.

  ## Examples

      iex> change_event_request(event_request)
      %Ecto.Changeset{source: %EventRequest{}}

  """
  def change_event_request(%EventRequest{} = event_request) do
    EventRequest.changeset(event_request, %{})
  end
end
