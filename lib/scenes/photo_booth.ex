defmodule TakeFive.Scene.PhotoBooth do
  use Scenic.Scene
  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  require Logger

  @target Mix.target()
  
  @system_info """
  MIX_TARGET: #{@target}
  MIX_ENV: #{Mix.env()}
  Scenic version: #{Scenic.version()}
  """

  @image_path :code.priv_dir(:take_five) |> Path.join("elder.jpg")
  @image_hash Scenic.Cache.Support.Hash.file!(@image_path, :sha)

  @graph Graph.build(font_size: 22, font: :roboto_mono)
         |> group(
           fn g ->
             g
             |> text("System")
             |> text(@system_info, translate: {10, 20}, font_size: 18)
           end,
           t: {10, 30}
         )
         |> group(
           fn g ->
             g
             |> text("ViewPort")
             |> text("", translate: {10, 20}, font_size: 18, id: :vp_info)
           end,
           t: {10, 110}
         )
         |> group(
           fn g ->
             g
             |> text("Input Devices")
             |> text("Devices are being loaded...",
               translate: {10, 20},
               font_size: 18,
               id: :devices
             )
           end,
           t: {280, 30},
           id: :device_list
         )
         |> group(fn g ->
           g
           |> button("Enable", id: :btn_enable, t: {0, 0}, theme: :success)
           |> button("Disable", id: :btn_disable, t: {0, 40}, theme: :danger)
           |> button("640x480", id: :btn_480, t: {0, 80})
           |> button("640x360", id: :btn_360, t: {0, 120})
           |> button("Oil Paint", id: :btn_effect, t: {0, 160})
         end, t: {10, 240})
  
  @countdown Graph.build(font_size: 100, font: :roboto_mono)
         |> group(
           fn g ->
             g
             |> text("3")
           end,
           t: {10, 30}
         )
  
  # --------------------------------------------------------
  def init(_, opts) do
    {:ok, info} = Scenic.ViewPort.info(opts[:viewport])

    vp_info = """
    size: #{inspect(Map.get(info, :size))}
    styles: #{inspect(Map.get(info, :styles, %{a: 1, b: 2}))}
    transforms: #{inspect(Map.get(info, :transforms, %{}))}
    drivers: #{inspect(Map.get(info, :drivers))}
    """

    Picam.set_size(640, 480)
    prev_w = 640
    prev_h = 480
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    Picam.set_preview_fullscreen(false)
    Picam.set_preview_enabled(true)

    graph = @countdown

    unless @target == :host do
      # subscribe to the simulated temperature sensor
      Process.send_after(self(), :update_devices, 100)
    end

    #Process.send_after(self(), :next_frame, 30)

    {:ok, graph, push: graph}
  end

  def handle_info(:next_frame, graph) do
    jpg = Picam.next_frame()
    Scenic.Cache.Base.put(Scenic.Cache.Static.Texture, @image_hash, jpg)

    Process.send_after(self(), :next_frame, 30)
    {:ok, graph}
  end

  unless @target == :host do
    # --------------------------------------------------------
    # Not a fan of this being polling. Would rather have InputEvent send me
    # an occasional event when something changes.
    def handle_info(:update_devices, graph) do
      Process.send_after(self(), :update_devices, 100)

      devices =
        InputEvent.enumerate()
        |> Enum.reduce("", fn {_, device}, acc ->
          Enum.join([acc, inspect(device), "\r\n"])
        end)

      # update the graph
      graph = Graph.modify(graph, :devices, &text(&1, devices))

      {:noreply, graph, push: graph}
    end
  end

  def filter_event({:click, :btn_enable} = event, _from, graph) do
    Picam.set_preview_enabled(true)
    {:cont, event, graph}
  end

  def filter_event({:click, :btn_disable} = event, _from, graph) do
    Picam.set_preview_enabled(false)
    Picam.set_img_effect(:none)
    {:cont, event, graph}
  end

  def filter_event({:click, :btn_480} = event, _from, graph) do
    Picam.set_size(640, 480)
    prev_w = 640
    prev_h = 480
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    {:cont, event, graph}
  end

  def filter_event({:click, :btn_360} = event, _from, graph) do
    Picam.set_size(640, 360)
    prev_w = 640
    prev_h = 360
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    {:cont, event, graph}
  end

  def filter_event({:click, :btn_effect} = event, _from, graph) do
    Picam.set_img_effect(:oilpaint)
    {:cont, event, graph}
  end

  def filter_event(event, _from, graph) do
    Logger.warn("Unhandled event: #{inspect event}")
    {:cont, event, graph}
  end
end
