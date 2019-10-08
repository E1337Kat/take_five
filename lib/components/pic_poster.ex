defmodule TakeFive.PicPoster do
  @moduledoc """
  Postimage keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc "send all images to the recipient"
  def post_images(pics, troll) do
    gts = DateTime.to_unix DateTime.utc_now
    
    pics
    |> Enum.with_index
    |> Enum.map(fn {pic, index} -> 
      post_image(pic, index, gts, troll) 
    end)
  end

  @doc "posts the image as jpeg"
  def post_image(jpg, index, gts, troll) do
    HTTPoison.post(
      "https://photos.grox.io/api/photos", 
      jpg, 
        [
          {"Content-Type", "image/jpeg"}, 
          {"Content-length", to_string byte_size(jpg)},
          {"Index", to_string(index)},
          {"Troll", troll}, 
          {"GTS", to_string(gts)}
   	    ]
      )
  end
  
  def get_troll() do
    case HTTPoison.get("https://photos.grox.io/api/troll") do
      {:ok, response} -> 
        response.body |> Jason.decode! |> Map.get("troll")
      _ -> 
        :random.uniform(8) == 1
    end
  end
  
end
