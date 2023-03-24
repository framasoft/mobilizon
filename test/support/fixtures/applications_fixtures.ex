defmodule Mobilizon.ApplicationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Mobilizon.Applications` context.
  """

  import Mobilizon.Factory

  @doc """
  Generate a application.
  """
  def application_fixture(attrs \\ %{}) do
    {:ok, application} =
      attrs
      |> Enum.into(%{
        name: "some name",
        client_id: "hello",
        client_secret: "secret",
        redirect_uris: ["somewhere", "else"],
        scope: "read"
      })
      |> Mobilizon.Applications.create_application()

    application
  end

  @doc """
  Generate a application_token.
  """
  def application_token_fixture(attrs \\ %{}) do
    user = insert(:user)

    {:ok, application_token} =
      attrs
      |> Enum.into(%{
        application_id: application_fixture().id,
        user_id: user.id,
        authorization_code: "some code",
        scope: "read",
        status: :pending
      })
      |> Mobilizon.Applications.create_application_token()

    application_token
  end

  @doc """
  Generate a application_device_activation.
  """
  def application_device_activation_fixture(attrs \\ %{}) do
    {:ok, application_device_activation} =
      attrs
      |> Enum.into(%{
        user_code: "hello",
        device_code: "computers",
        expires_in: 600,
        application_id: application_fixture().id,
        scope: "read"
      })
      |> Mobilizon.Applications.create_application_device_activation()

    application_device_activation
  end
end
