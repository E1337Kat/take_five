use Mix.Config

config :take_five, :viewport, %{
  name: :main_viewport,
  default_scene: {TakeFive.Scene.SysInfo, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      opts: [title: "MIX_TARGET=host, app = :take_five"]
    }
  ]
}
