use Mix.Config

config :take_five, :viewport, %{
  name: :main_viewport,
  # default_scene: {ScenicPhotoBoothNerves.Scene.Crosshair, nil},
  default_scene: {PhotoBooth.Scene.SysInfo, nil},
  size: {800, 480},
  #size: {1920, 1080},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
    %{
      module: Scenic.Driver.Nerves.Touch,
      opts: [
        device: "FT5406 memory based driver",
        calibration: {{1, 0, 0}, {1, 0, 0}}
      ]
    }
  ]
}
