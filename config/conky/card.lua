-- Ve nen the bo goc kieu widget macOS cho moi cua so conky.
require 'cairo'
pcall(require, 'cairo_xlib')

local RADIUS = 22
local BG = { 0.11, 0.11, 0.12, 0.58 }   -- xam dam, trong suot nhu macOS dark widget

function conky_card()
  if conky_window == nil then return end
  local w, h = conky_window.width, conky_window.height
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                       conky_window.visual, w, h)
  local cr = cairo_create(cs)
  local r = RADIUS
  cairo_new_sub_path(cr)
  cairo_arc(cr, w - r, r,     r, -math.pi / 2, 0)
  cairo_arc(cr, w - r, h - r, r, 0, math.pi / 2)
  cairo_arc(cr, r,     h - r, r, math.pi / 2, math.pi)
  cairo_arc(cr, r,     r,     r, math.pi, 3 * math.pi / 2)
  cairo_close_path(cr)
  cairo_set_source_rgba(cr, BG[1], BG[2], BG[3], BG[4])
  cairo_fill(cr)
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end
