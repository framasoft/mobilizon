defmodule Mobilizon.ApplicationsTest do
  use Mobilizon.DataCase

  alias Mobilizon.Applications

  describe "applications" do
    alias Mobilizon.Applications.Application

    import Mobilizon.ApplicationsFixtures

    @invalid_attrs %{name: nil}

    test "list_applications/0 returns all applications" do
      application = application_fixture()
      assert Applications.list_applications() == [application]
    end

    test "get_application!/1 returns the application with given id" do
      application = application_fixture()
      assert Applications.get_application!(application.id) == application
    end

    test "create_application/1 with valid data creates a application" do
      valid_attrs = %{
        name: "some name",
        client_id: "hello",
        client_secret: "secret",
        redirect_uris: "somewhere\nelse"
      }

      assert {:ok, %Application{} = application} = Applications.create_application(valid_attrs)
      assert application.name == "some name"
      assert application.client_id == "hello"
      assert application.client_secret == "secret"
      assert application.redirect_uris == "somewhere\nelse"
    end

    test "create_application/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Applications.create_application(@invalid_attrs)
    end

    test "update_application/2 with valid data updates the application" do
      application = application_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Application{} = application} =
               Applications.update_application(application, update_attrs)

      assert application.name == "some updated name"
    end

    test "update_application/2 with invalid data returns error changeset" do
      application = application_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Applications.update_application(application, @invalid_attrs)

      assert application == Applications.get_application!(application.id)
    end

    test "delete_application/1 deletes the application" do
      application = application_fixture()
      assert {:ok, %Application{}} = Applications.delete_application(application)
      assert_raise Ecto.NoResultsError, fn -> Applications.get_application!(application.id) end
    end

    test "change_application/1 returns a application changeset" do
      application = application_fixture()
      assert %Ecto.Changeset{} = Applications.change_application(application)
    end
  end

  describe "application_tokens" do
    alias Mobilizon.Applications.ApplicationToken

    import Mobilizon.ApplicationsFixtures
    import Mobilizon.Factory

    @invalid_attrs %{user_id: nil}

    test "list_application_tokens/0 returns all application_tokens" do
      application_token = application_token_fixture()
      assert Applications.list_application_tokens() == [application_token]
    end

    test "get_application_token!/1 returns the application_token with given id" do
      application_token = application_token_fixture()
      assert Applications.get_application_token!(application_token.id) == application_token
    end

    test "create_application_token/1 with valid data creates a application_token" do
      user = insert(:user)
      application = application_fixture()

      valid_attrs = %{
        user_id: user.id,
        application_id: application.id,
        authorization_code: "hey hello"
      }

      assert {:ok, %ApplicationToken{} = application_token} =
               Applications.create_application_token(valid_attrs)

      assert application_token.user_id == user.id
      assert application_token.application_id == application.id
      assert application_token.authorization_code == "hey hello"
    end

    test "create_application_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Applications.create_application_token(@invalid_attrs)
    end

    test "update_application_token/2 with valid data updates the application_token" do
      application_token = application_token_fixture()
      update_attrs = %{authorization_code: nil}

      assert {:ok, %ApplicationToken{} = application_token} =
               Applications.update_application_token(application_token, update_attrs)

      assert is_nil(application_token.authorization_code)
    end

    test "update_application_token/2 with invalid data returns error changeset" do
      application_token = application_token_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Applications.update_application_token(application_token, @invalid_attrs)

      assert application_token == Applications.get_application_token!(application_token.id)
    end

    test "delete_application_token/1 deletes the application_token" do
      application_token = application_token_fixture()
      assert {:ok, %ApplicationToken{}} = Applications.delete_application_token(application_token)

      assert_raise Ecto.NoResultsError, fn ->
        Applications.get_application_token!(application_token.id)
      end
    end

    test "change_application_token/1 returns a application_token changeset" do
      application_token = application_token_fixture()
      assert %Ecto.Changeset{} = Applications.change_application_token(application_token)
    end
  end

  describe "application_device_activation" do
    alias Mobilizon.Applications.ApplicationDeviceActivation

    import Mobilizon.ApplicationsFixtures

    @invalid_attrs %{}

    test "list_application_device_activation/0 returns all application_device_activation" do
      application_device_activation = application_device_activation_fixture()
      assert Applications.list_application_device_activation() == [application_device_activation]
    end

    test "get_application_device_activation!/1 returns the application_device_activation with given id" do
      application_device_activation = application_device_activation_fixture()

      assert Applications.get_application_device_activation!(application_device_activation.id) ==
               application_device_activation
    end

    test "create_application_device_activation/1 with valid data creates a application_device_activation" do
      valid_attrs = %{}

      assert {:ok, %ApplicationDeviceActivation{} = application_device_activation} =
               Applications.create_application_device_activation(valid_attrs)
    end

    test "create_application_device_activation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Applications.create_application_device_activation(@invalid_attrs)
    end

    test "update_application_device_activation/2 with valid data updates the application_device_activation" do
      application_device_activation = application_device_activation_fixture()
      update_attrs = %{}

      assert {:ok, %ApplicationDeviceActivation{} = application_device_activation} =
               Applications.update_application_device_activation(
                 application_device_activation,
                 update_attrs
               )
    end

    test "update_application_device_activation/2 with invalid data returns error changeset" do
      application_device_activation = application_device_activation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Applications.update_application_device_activation(
                 application_device_activation,
                 @invalid_attrs
               )

      assert application_device_activation ==
               Applications.get_application_device_activation!(application_device_activation.id)
    end

    test "delete_application_device_activation/1 deletes the application_device_activation" do
      application_device_activation = application_device_activation_fixture()

      assert {:ok, %ApplicationDeviceActivation{}} =
               Applications.delete_application_device_activation(application_device_activation)

      assert_raise Ecto.NoResultsError, fn ->
        Applications.get_application_device_activation!(application_device_activation.id)
      end
    end

    test "change_application_device_activation/1 returns a application_device_activation changeset" do
      application_device_activation = application_device_activation_fixture()

      assert %Ecto.Changeset{} =
               Applications.change_application_device_activation(application_device_activation)
    end
  end
end
