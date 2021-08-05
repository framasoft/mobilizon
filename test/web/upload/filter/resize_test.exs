defmodule Mobilizon.Web.Upload.Filter.ResizeTest do
  use Mobilizon.DataCase, async: true
  alias Mobilizon.Web.Upload.Filter.Resize

  test "does not resize if dimensions are ok" do
    assert {100, 150} == Resize.limit_sizes({100, 150})
  end

  test "does resize only width if needed" do
    assert {1_920, 960} == Resize.limit_sizes({2_000, 1_000})
  end

  test "does resize only height if needed" do
    assert {540, 1_080} == Resize.limit_sizes({1_000, 2_000})
  end

  test "does resize if dimentions are really big, and keeps ratio" do
    assert {724, 1080} == Resize.limit_sizes({10_050, 15_000})
  end
end
