defmodule TakeFive.Scene.PhotoBooth do
  use Scenic.Scene
  alias Scenic.Graph
  alias Pex.Core.PhotoBooth

  import Scenic.Primitives
  import Scenic.Components

  require Logger

  @start_graph Graph.build(font_size: 50, font: :roboto_mono)
               |> group(
                  fn g ->
                    g
                    |> button(
                      "Start",
                      width: 100,
                      height: 100,
                      id: :btn_take_pic,
                      t: {30, 200}, theme: :success)
                  end, [])

  @countdown Graph.build(font_size: 250, font: :roboto_mono)
  
  @preview Graph.build(font_size: 100, font: :roboto_mono)

  @choose Graph.build(font_size: 50, font: :roboto_mono)
              |> group(
              fn g ->
                g
                |> button(
                "Keep",
                width: 100,
                height: 100,
                id: :btn_keep,
                t: {30, 100}, theme: :success)
                |> button(
                "Discard",
                width: 100,
                height: 100,
                id: :btn_discard,
                t: {30, 230}, theme: :danger)
              end, [])

  # --------------------------------------------------------
  def init(_, _opts) do
    initialize_picam()
    seed_random_numbers()

    graph = @start_graph

    push_graph(graph)

    #Process.send_after(self(), :next_frame, 30)
    troll_mode =
      [true, false, false]
      |> Enum.shuffle
      |> List.first

    {:ok, {graph, PhotoBooth.new(troll_mode)}}
  end

  def seed_random_numbers() do
    :random.seed(DateTime.to_unix(DateTime.utc_now))
  end

  def initialize_picam() do
    Picam.set_size(640, 480)
    prev_w = 640
    prev_h = 480
    Picam.set_preview_window(800 - prev_w, 480 - prev_h, prev_w, prev_h)
    Picam.set_preview_fullscreen(false)
    Picam.set_preview_enabled(true)
  end

  def next_countdown(scene, nil), do: next_countdown(scene, {0, 0})
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

  def advance(%{mode: :countdown}=booth) do
    send(self(), :countdown_tick)
    booth
  end
  def advance(%{mode: :choosing}=booth) do
    send(self(), :choose)
    
    booth
    |> Map.put(:photos, Enum.reverse(booth.photos))
  end
  
  def reverse_pics(booth) do
    pics = 
      booth.taken 
      |> Enum.reverse


    Map.put booth, :taken, pics
  end
  
  def random_text(false) do
    ["Nice!", "Fine!", "Cheese!", "Click!", "Pretty!", "Smile!"]
    |> Enum.shuffle
    |> hd
  end
  def random_text(true) do
    ["ok?", "Hm...", "fine?", "alright.", "well..."]
    |> Enum.shuffle
    |> hd
  end

  def countdown(%{countdown_list: []}=booth) do
    jpg = Picam.next_frame()
    updated_booth = 
      booth
      |> PhotoBooth.countdown
      #add say cheese message
      |> PhotoBooth.add_taken_photo(jpg)
    
    
    show_photo(updated_booth)
    
    
    
    updated_booth
  end
  def countdown(booth) do
    {_count, milliseconds} = booth.countdown_list |> List.first
    Process.send_after(self(), :countdown_tick, milliseconds)
    PhotoBooth.countdown(booth)
  end
  
  def do_choose(booth) do
    image_hash = present_photo(booth)

    @choose
    |> rect( {640, 480}, fill: {:image, image_hash}, t: {160, 0})
  end
  
  def show_photo(booth) do
    Process.send_after(self(), :end_preview, 750)
    image_hash = present_photo(booth)
    
    message = random_text(booth.troll)
    
    @preview
    |> rect( {640, 480}, fill: {:image, image_hash}, t: {160, 0})
    |> group(
        fn g ->
          g
          |> text_field(message, t: {10, 180} )
        end, [])
    |> push_graph
  end
  
  def present_photo(booth) do
    Picam.set_preview_enabled(false)
    
    jpg = booth.photos |> hd

    image_hash = Scenic.Cache.Support.Hash.binary!(jpg, :sha)
    Scenic.Cache.Base.put(Scenic.Cache.Static.Texture, image_hash, jpg)
    image_hash
  end
  
  def end_show_photo(booth) do
    Picam.set_preview_enabled(true)
    
    booth
    |> advance
  end
  
  def handle_info(:countdown_tick, {_graph, booth}) do
    graph =
      @countdown
      |> next_countdown(List.first(booth.countdown_list))

    {:noreply, {graph, countdown(booth)}, push: graph}
  end
  
  def handle_info(:choose, {_graph, booth}) do
    graph = do_choose(booth)

    {:noreply, {graph, booth}, push: graph}
  end

  def handle_info(:end_preview, {graph, booth}) do
    {:noreply, {graph, end_show_photo(booth)}, push: graph}
  end

  def filter_event({:click, :btn_take_pic} = event, _from, {graph, booth}) do
    send(self(), :countdown_tick)
    {:cont, event, {graph, booth}}
  end

  def filter_event({:click, :btn_keep} = event, _from, {graph, booth}) do
    send(self(), :choose)
    {:cont, event, {graph, PhotoBooth.choose(booth, :accept)}}
  end

  def filter_event({:click, :btn_discard} = event, _from, {graph, booth}) do
    send(self(), :choose)
    {:cont, event, {graph, PhotoBooth.choose(booth, :reject)}}
  end

  # keep
  def filter_event(event, _from, {graph, booth}) do
    Logger.warn("Unhandled event: #{inspect event}")
    {:cont, event, {graph, booth}}
  end
end
