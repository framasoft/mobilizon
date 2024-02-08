# The following module is taken from this issue
# https://github.com/swoosh/swoosh/issues/488#issuecomment-1671224765

defmodule Mobilizon.Tests.SwooshAssertions do
  @moduledoc ~S"""
  Assertions for emails.

  The assertions provided by this module work by pattern matching
  against all emails received by the test process against the
  `Swoosh.Email` struct. For example:

      assert_email_sent %{subject: "You got a message"}

  If you want to be additionally explicit, you might:

      assert_email_sent %Swoosh.Email{subject: "You got a message"}

  If emails are being sent concurrently, you can use `assert_email_sending/2`:

      assert_email_sending %{subject: "You got a message"}

  Both functions will return the matched email if the assertion succeeds.
  You can then perform further matches on it:

      email = assert_email_sent %Swoosh.Email{subject: "You got a message"}
      assert email.from == {"MyApp", "no-reply@example.com"}

  Using pattern matching imposes two limitations. The first one is that you
  must match precisely the Swoosh.Email structure. For example, the following
  will not work:

      assert_email_sent %{to: "foobar@example.com"}

  That's because `Swoosh.Email` keeps the field as a list. This will work:

      assert_email_sent %{to: [{"FooBar", "foobar@example.com"}]}

  You are also not allowed to have interpolations. For example, the following
  will not work:

      assert_email_sent %{
        subject: "You have been invited to #{org.name}",
        to: [{user.name, user.email}]
      }

  However, you can rely on pattern matching and rewrite it as:

      email = assert_email_sent %{subject: "You have been invited to " <> org_name}
      assert org_name == org.name
      assert email.to == [{user.name, user.email}]

  """

  @doc """
  Matches an email has been sent.

  See moduledoc for more information.
  """
  defmacro assert_email_sent(pattern) do
    quote do
      {:email, email} = assert_received({:email, unquote(pattern)})
      email
    end
  end

  @doc """
  Matches an email is sending (within a timeout).

  See moduledoc for more information.
  """
  defmacro assert_email_sending(
             pattern,
             timeout \\ Application.fetch_env!(:ex_unit, :assert_receive_timeout)
           ) do
    quote do
      {:email, email} = assert_receive({:email, unquote(pattern)}, unquote(timeout))
      email
    end
  end

  @doc """
  Refutes an email matching pattern has been sent.

  The opposite of `assert_email_sent`.
  """
  defmacro refute_email_sent(pattern) do
    quote do
      refute_received({:email, unquote(pattern)})
    end
  end
end
