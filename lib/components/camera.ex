defmodule TakeFive.Camera do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(_opts) do
    Picam.set_size(1280, 720)
    Picam.set_preview_fullscreen(false)
    Picam.set_preview_window(400, 300, 1280, 720)
    Picam.set_preview_enabled(true)
    Picam.set_vflip(true)

    :ignore
  end
end
