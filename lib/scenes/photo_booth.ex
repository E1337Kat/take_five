defmodule TakeFive.Scene.PhotoBooth do
  use Scenic.Scene
  alias Scenic.Graph
  alias Pex.Core.PhotoBooth

  import Scenic.Primitives
  import Scenic.Components

  require Logger

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
  
  # --------------------------------------------------------
  def init(_, _opts) do
    initialize_picam()
    
    graph = @start_graph
    
    push_graph(graph)

    # subscribe to the simulated temperature sensor
    Process.send_after(self(), :next_camera_frame, 100)

    #Process.send_after(self(), :next_frame, 30)

    {:ok, {graph, PhotoBooth.new(false)}}
  end
  
  def initialize_picam() do
    Picam.set_size(640, 480)
    prev_w = 640
    prev_h = 480
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    Picam.set_preview_fullscreen(false)
    Picam.set_preview_enabled(true)
  end
  
  def next_countdown(scene, {number, _milliseconds}) do
    scene
    |> group(
      fn g ->
        g
        |> text("#{number}")
      end,
      t: {30, 300}
    )
  end

  def handle_info(:next_frame, graph) do
    jpg = Picam.next_frame()
    Scenic.Cache.Base.put(Scenic.Cache.Static.Texture, @image_hash, jpg)

    Process.send_after(self(), :next_frame, 30)
    {:ok, graph}
  end

  # --------------------------------------------------------
  # Not a fan of this being polling. Would rather have InputEvent send me
  # an occasional event when something changes.
  def handle_info(:next_camera_frame, {graph, booth}) do
    Process.send_after(self(), :next_camera_frame, 100)

    devices =
      InputEvent.enumerate()
      |> Enum.reduce("", fn {_, device}, acc ->
        Enum.join([acc, inspect(device), "\r\n"])
      end)

    # update the graph
    graph = Graph.modify(graph, :devices, &text(&1, devices))

    {:noreply, {graph, booth}, push: graph}
  end
  
  def countdown(booth) do
    {count, milliseconds} = booth.countdown_list |> List.first
    Process.send_after(self(), :countdown_tick, milliseconds)
    PhotoBooth.countdown(booth)
  end

  def filter_event({:click, :btn_take_pic} = event, _from, {graph, booth}) do
    send(self(), :countdown_tick)
    {:cont, event, {graph, booth}}
  end
  
  def handle_info(:countdown_tick, {graph, booth}) do
    graph = 
      @countdown
      |> next_countdown(hd(booth.countdown_list))
    
    {:noreply, {graph, countdown(booth)}, push: graph}
  end
  

  # keep
  def filter_event(event, _from, {graph, booth}) do
    Logger.warn("Unhandled event: #{inspect event}")
    {:cont, event, {graph, booth}}
  end
end
