function love.conf(t)
  t.identity = 'skelerun'
  t.version = '11.4'
  t.window.title = 'SKELERUN — The Sunken Keep'
  t.window.width = 600
  t.window.height = 960
  t.window.resizable = true
  t.window.minwidth = 480
  t.window.minheight = 768
  t.window.vsync = 1
  t.modules.physics = false
end
