defmodule ReportsGeneratorFreelancerParallel do
  alias ReportsGeneratorFreelancerParallel.Parser

  @developers [
    "Daniele",
    "Mayk",
    "Giuliano",
    "Cleiton",
    "Jakeliny",
    "Joseph",
    "Rafael",
    "Diego",
    "Vinicius",
    "Danilo"
  ]

  @months_map %{
    1 => "Janeiro",
    2 => "Fevereiro",
    3 => "Março",
    4 => "Abril",
    5 => "Maio",
    6 => "Junho",
    7 => "Julho",
    8 => "Agosto",
    9 => "Setembro",
    10 => "Outubro",
    11 => "Novembro",
    12 => "Dezembro"
  }

  @months_list [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ]

  def build(file_name) do
    parsed_file = Parser.parse_file(file_name)
    all_hours = build_all_hours(parsed_file)
    hours_per_month = build_monthly_hours(parsed_file)
    hours_per_year = build_yearly_hours(parsed_file)

    build_report_map(all_hours, hours_per_month, hours_per_year)
  end

  def build_from_many(file_names) when not is_list(file_names),
    do: {:error, "Please provide a list of strings"}

  def build_from_many(file_names) do
    result =
      file_names
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc_full(), fn {:ok, result}, acc ->
        sum_reports(result, acc)
      end)

    {:ok, result}
  end

  defp build_all_hours(parsed_file) do
    parsed_file
    |> Enum.reduce(report_acc_day(), fn line, acc ->
      sum_all_hours(line, acc)
    end)
  end

  defp build_monthly_hours(parsed_file) do
    parsed_file
    |> Enum.reduce(report_acc_month(), fn line, acc ->
      sum_monthly_hours(line, acc)
    end)
  end

  defp build_yearly_hours(parsed_file) do
    parsed_file
    |> Enum.reduce(report_acc_year(), fn line, acc ->
      sum_yearly_hours(line, acc)
    end)
  end

  defp report_acc_day() do
    Enum.into(@developers, %{}, &{&1, 0})
  end

  defp report_acc_month() do
    months = Enum.into(@months_list, %{}, &{&1, 0})
    Enum.into(@developers, %{}, &{&1, months})
  end

  defp report_acc_year() do
    months = Enum.into(2016..2020, %{}, &{&1, 0})
    Enum.into(@developers, %{}, &{&1, months})
  end

  defp report_acc_full() do
    build_report_map(report_acc_day(), report_acc_month(), report_acc_year())
  end

  defp sum_all_hours([name, hours, _day, _month, _year], acc) do
    %{acc | name => acc[name] + hours}
  end

  defp sum_monthly_hours([name, hours, _day, month, _year], acc) do
    %{acc | name => %{acc[name] | @months_map[month] => acc[name][@months_map[month]] + hours}}
  end

  defp sum_yearly_hours([name, hours, _day, _month, year], acc) do
    %{acc | name => %{acc[name] | year => acc[name][year] + hours}}
  end

  defp sum_reports(map1, map2) do
    all_hours =
      Map.merge(map1["all_hours"], map2["all_hours"], fn _key, value1, value2 ->
        value1 + value2
      end)

    hours_per_month = deep_merge(map1["hours_per_month"], map2["hours_per_month"])
    hours_per_year = deep_merge(map1["hours_per_year"], map2["hours_per_year"])

    build_report_map(all_hours, hours_per_month, hours_per_year)
  end

  defp deep_merge(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 ->
      Map.merge(value1, value2, fn _key, dev1, dev2 ->
        dev1 + dev2
      end)
    end)
  end

  defp build_report_map(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end
end
