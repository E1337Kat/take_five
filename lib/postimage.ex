defmodule Postimage do
  @moduledoc """
  Postimage keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """


  @doc "Sends the image to the recipient"
  defp send_post(url, photo, headers) do
    HTTPoison.post(url, photo, headers)
  end

  @doc "posts the image after finding out what it is"
  def post_image(photo, index, gts) do
    url = "https://postman-echo.com/post"
    IO.puts MIME.from_path photo
    headers = [{"Accept", MIME.from_path(photo)},
	       {"Index", index},
	       {"GTS", gts},
	       {"UserID", "someuuid"}
	      ]

    send_post url, photo, headers
  end
  
end
