defmodule ReportsGeneratorFreelancerParallel.Parser do
  def parse_file(file_name) do
    "reports/#{file_name}"
    |> File.stream!()
    |> Stream.map(fn line -> parse_line(line) end)
  end

  defp parse_line(line) do
    line
    |> String.trim()
    |> String.split(",")
    |> Enum.map(fn string -> convert_integer(string) end)
  end

  defp convert_integer(string) do
    case Integer.parse(string) do
      {int, _string} -> int
      :error -> string
    end
  end
end
