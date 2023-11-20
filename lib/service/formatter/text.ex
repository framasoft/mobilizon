defmodule Mobilizon.Service.Formatter.Text do
  @moduledoc """
  Helps to format text blocks

  Inspired from https://elixirforum.com/t/is-there-are-text-wrapping-library-for-elixir/21733/4
  Using the Knuth-Plass Line Wrapping Algorithm https://www.students.cs.ubc.ca/~cs-490/2015W2/lectures/Knuth.pdf
  """

  def quote_paragraph(string, max_line_length) do
    paragraph(string, max_line_length, "> ")
  end

  def paragraph(string, max_line_length, prefix \\ "") do
    string
    |> String.split("\n\n", trim: true)
    |> Enum.map_join("\n#{prefix}\n", &subparagraph(&1, max_line_length, prefix))
  end

  defp subparagraph(string, max_line_length, prefix) do
    [word | rest] = String.split(string, ~r/\s+/, trim: true)

    rest
    |> lines_assemble(max_line_length - String.length(prefix), String.length(word), word, [])
    |> Enum.map_join("\n", &"#{prefix}#{&1}")
  end

  defp lines_assemble([], _, _, line, acc), do: [line | acc] |> Enum.reverse()

  defp lines_assemble([word | rest], max, line_length, line, acc) do
    if line_length + 1 + String.length(word) > max do
      lines_assemble(rest, max, String.length(word), word, [line | acc])
    else
      lines_assemble(rest, max, line_length + 1 + String.length(word), line <> " " <> word, acc)
    end
  end
end
