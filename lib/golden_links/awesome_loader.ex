defmodule GoldenLinks.AwesomeLoader do
  alias GoldenLinks.{AwesomeCategory, Repo}
  require Logger
  @scrap_url "https://github.com/h4cc/awesome-elixir"

  def init() do
    HTTPoison.start
  end

  def load() do
    init()
    dest = self()
    category_names = get_categories()
    repos = get_repos()
    pids = for category <- :lists.zip(category_names, repos) do
      Kernel.spawn_link(fn ->
        scores = get_scores_cat(category, [])
        if !is_nil(scores), do: Process.send_after(dest, {self(), scores}, 40000) end)
    end
    for pid <- pids do
      receive do
        {^pid, {name, repos}} ->
          category = Repo.insert!(%AwesomeCategory{category: name})
          for repo <- repos do
            Ecto.build_assoc(category, :repositories, repo)
            |> Repo.insert!
          end
        after 160000 -> ""
      end
    end
  end


  def get_all_info(url\\@scrap_url) do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}}->
        body
        |> Floki.parse_document!
      {:ok, %HTTPoison.Response{status_code: 400}} ->
        Logger.info("Bad request has been received from page #{url}")
        []
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        Logger.info("Page #{url} not found")
        []
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.info("Received #{inspect status_code} and body #{inspect body} message for page #{url}")
        []
      {:ok, other} ->
          Logger.info("Received #{inspect other} message for page #{url}")
          []
      {:error, %HTTPoison.Error{reason: reason}}->
        Logger.info("Received #{inspect reason} message for page #{url}")
        []
    end
  end
  def get_categories(url\\@scrap_url) do
    case get_all_info(url) do
      [] -> []
      info ->
        info_full = info |> Floki.find("article> h1:first-of-type ~ h2")
        info_after = info |> Floki.find("article> h1:nth-of-type(2) ~ h2")
        Enum.reject(info_full, fn inf -> Enum.member?(info_after, inf) end)
        |> Floki.text(sep: ";")
        |> String.split(";")
    end
  end

  def get_category_descriptions(url\\@scrap_url) do
    case get_all_info(url) do
      [] -> []
      info ->
        info_full = info |> Floki.find("article> h1:first-of-type ~ h2+p")
        info_after = info |> Floki.find("article> h1:nth-of-type(2) ~ h2+p")
        Enum.reject(info_full, fn inf -> Enum.member?(info_after, inf) end)
        |> Floki.text(sep: ";")
        |> String.split(";")
    end
  end

  def get_repos(url\\@scrap_url) do
    case get_all_info(url) do
      [] -> []
      info ->
        info_full = info |> Floki.find("article> h1:first-of-type ~ h2~ul")
        info_after = info |> Floki.find("article> h1:nth-of-type(2) ~ h2~ul")
        Enum.reject(info_full, fn inf -> Enum.member?(info_after, inf) end)
        |> parse_tree

    end
  end

  def get_scores(%{url: "https://github" <> _ = url} = repo) do
    case get_all_info(url) do
      [] -> nil
      info ->
        days = info
        |> Floki.find("relative-time.no-wrap")
        |> Floki.attribute("datetime")
        |> calc_days
        [stars] = info
        |> Floki.find("span#repo-stars-counter-star")
        |> Floki.attribute("title")
        Map.merge(repo, %{'days after last commit': days, 'github stars': stars})
    end
  end
  def get_scores(_), do: nil

  def get_scores_cat({name,[]}, awesomes), do: {name,awesomes}
  def get_scores_cat({name,[repo | repos]}, awesomes) do
    :timer.sleep(40000)
    case get_scores(repo) do
      nil ->
        get_scores_cat({name, repos}, awesomes)
      awesome ->
        get_scores_cat({name, repos}, [awesome|awesomes])
      end
  end
  def get_scores_cat(_,_), do: nil

  def parse_tree({}), do: {}
  def parse_tree({"a",[{"href", ref}], [name]}), do: %{repository: name, url: ref}
  def parse_tree({"a",[{"href", ref}|_], [name]}), do: %{repository: name, url: ref}
  def parse_tree({"li",_, [expr, " - " <> desc]}), do: :maps.merge(parse_tree(expr), %{description: desc})
  def parse_tree({"li",_, [expr, " - " <> desc, expr2, desc2]}),
                do: :maps.merge(parse_tree(expr), %{description: desc<>make_url(expr2)<>desc2})
  def parse_tree({"ul",_, expr}) , do: parse_tree(expr)
  def parse_tree(expr) when is_list(expr), do: expr |> parse_tree([])
  def parse_tree(_), do: nil

  def parse_tree([], expr) when is_list(expr), do: expr
  def parse_tree([node|tree], expr) do
    case parse_tree(node) do
      nil -> parse_tree(tree, expr)
      map -> parse_tree(tree, expr ++ [map])
    end
  end


  def p_get_scores(categories) do
    dest = self()
    pids = for category <- categories do
      Kernel.spawn_link(fn ->
        scores = get_scores_cat(category, [])
        if !is_nil(scores), do: Process.send_after(dest, {self(), scores}, 40000) end)
    end
    for pid <- pids do
      receive do
        {^pid, awesome} ->
          IO.inspect "#{inspect awesome}"
        after 160000 -> ""
      end
    end
  end


  defp make_url({"a",[{"href",ref},{"rel", rel}],_}), do: ref <> " [release:" <> rel <> "]"
  defp make_url(_), do: ""

  defp calc_days(datetime) when is_binary(datetime) do
    {:ok, dt,_} = DateTime.from_iso8601(datetime)
    Date.diff(DateTime.utc_now, dt)
    |> Integer.to_string
  end
  defp calc_days([datetime|_])do
    datetime
    |>calc_days
  end
  defp calc_days(_), do: ""
end
