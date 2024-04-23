defmodule Alipay.Utils do
  @moduledoc false

  @spec now_unix :: integer
  def now_unix, do: System.system_time(:second)
  @spec now_unix_mill :: integer
  def now_unix_mill, do: System.system_time(:millisecond)
  @spec timestamp_str :: String.t()
  def timestamp_str, do: DateTime.utc_now() |> DateTime.add(8, :hour) |> Calendar.strftime("%c")

  def expand_file({:app_dir, app, path}) do
    file = Application.app_dir(app, path)

    if File.exists?(file) do
      {:ok, file}
    else
      {:error, :not_exists}
    end
  end

  def expand_file(path) when is_binary(path) do
    file = Path.expand(path)

    if File.exists?(file) do
      {:ok, file}
    else
      {:error, :not_exists}
    end
  end

  def expand_file(_path), do: {:error, :bad_arg}
end
