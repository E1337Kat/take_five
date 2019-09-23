defmodule TakeFive.Scene.PhotoBooth do
  use Scenic.Scene
  alias Scenic.Graph

  import Scenic.Primitives
  import Scenic.Components

  require Logger

  @target Mix.target()

  @image_path :code.priv_dir(:take_five) |> Path.join("elder.jpg")
  @image_hash Scenic.Cache.Support.Hash.file!(@image_path, :sha)

  @start_graph Graph.build(font_size: 50, font: :roboto_mono)
               |> group(
                  fn g ->
                    g
                    |> button(
                      "Start", 
                      width: 100, 
                      height: 100, 
                      id: :btn_take_pic, 
                      t: {10, 240}, theme: :success)
                  end, [])

  @countdown Graph.build(font_size: 250, font: :roboto_mono)
         |> group(
           fn g ->
             g
             |> text("3")
           end,
           t: {30, 300}
         )
  
  # --------------------------------------------------------
  def init(_, _opts) do
    initialize_picam()
    
    graph = @start_graph

    unless @target == :host do
      # subscribe to the simulated temperature sensor
      Process.send_after(self(), :update_devices, 100)
    end

    #Process.send_after(self(), :next_frame, 30)

    {:ok, graph, push: graph}
  end
  
  def initialize_picam() do
    Picam.set_size(640, 480)
    prev_w = 640
    prev_h = 480
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    Picam.set_preview_fullscreen(false)
    Picam.set_preview_enabled(true)
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

  # keep
  
  def filter_event({:click, :btn_take_pic} = event, _from, _graph) do
    graph = @countdown
    # todo: get camera state
    # todo: 
    {:cont, event, graph}
  end

  def filter_event(event, _from, graph) do
    Logger.warn("Unhandled event: #{inspect event}")
    {:cont, event, graph}
  end
end
