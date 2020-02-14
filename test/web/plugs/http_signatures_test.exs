defmodule Mobilizon.Web.Plug.HTTPSignaturesTest do
  use Mobilizon.Web.ConnCase
  import Mock

  alias Mobilizon.Federation.HTTPSignatures.Signature
  alias Mobilizon.Web.Plugs.HTTPSignatures, as: HTTPSignaturesPlug

  test "tests that date window is acceptable" do
    date = NaiveDateTime.utc_now() |> Timex.shift(hours: -3) |> Signature.generate_date_header()

    with_mock HTTPSignatures, validate_conn: fn _ -> true end do
      conn =
        build_conn()
        |> put_req_header("signature", "signature")
        |> put_req_header("date", date)
        |> HTTPSignaturesPlug.call(%{})

      assert called(HTTPSignatures.validate_conn(:_))
      assert conn.assigns.valid_signature
    end
  end

  test "tests that date window is not acceptable (already passed)" do
    date = NaiveDateTime.utc_now() |> Timex.shift(hours: -30) |> Signature.generate_date_header()

    with_mock HTTPSignatures, validate_conn: fn _ -> true end do
      conn =
        build_conn()
        |> put_req_header("signature", "signature")
        |> put_req_header("date", date)
        |> HTTPSignaturesPlug.call(%{})

      refute conn.assigns.valid_signature
      assert called(HTTPSignatures.validate_conn(:_))
    end
  end

  test "tests that date window is not acceptable (in the future)" do
    date = NaiveDateTime.utc_now() |> Timex.shift(hours: 30) |> Signature.generate_date_header()

    with_mock HTTPSignatures, validate_conn: fn _ -> true end do
      conn =
        build_conn()
        |> put_req_header("signature", "signature")
        |> put_req_header("date", date)
        |> HTTPSignaturesPlug.call(%{})

      refute conn.assigns.valid_signature
      assert called(HTTPSignatures.validate_conn(:_))
    end
  end
end
