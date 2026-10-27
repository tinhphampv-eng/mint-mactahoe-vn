-- macOS 26 style desktop widgets for conky: glass cards, Apple-like calendar, activity rings.
require 'cairo'
pcall(require, 'cairo_xlib')

local SHADOW = 12     -- space around the card for the soft shadow
local RADIUS = 24
local FONT = 'Inter'

local function rounded(cr, x, y, w, h, r)
  cairo_new_sub_path(cr)
  cairo_arc(cr, x + w - r, y + r,     r, -math.pi / 2, 0)
  cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
  cairo_arc(cr, x + r,     y + h - r, r, math.pi / 2, math.pi)
  cairo_arc(cr, x + r,     y + r,     r, math.pi, 3 * math.pi / 2)
  cairo_close_path(cr)
end

local function with_cairo(fn)
  if conky_window == nil then return end
  local w, h = conky_window.width, conky_window.height
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                       conky_window.visual, w, h)
  local cr = cairo_create(cs)
  fn(cr, w, h)
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

local function text(cr, s, x, y, size, bold, r, g, b, a, align)
  cairo_select_font_face(cr, FONT, CAIRO_FONT_SLANT_NORMAL,
                         bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
  cairo_set_font_size(cr, size)
  local ext = cairo_text_extents_t:create()
  cairo_text_extents(cr, s, ext)
  if align == 'center' then x = x - ext.width / 2 - ext.x_bearing
  elseif align == 'right' then x = x - ext.width - ext.x_bearing end
  cairo_move_to(cr, x, y)
  cairo_set_source_rgba(cr, r, g, b, a)
  cairo_show_text(cr, s)
end

-- Glass card: soft shadow, translucent fill, top sheen, hairline border
function conky_card()
  with_cairo(function(cr, w, h)
    local x, y, cw, ch = SHADOW, SHADOW - 2, w - 2 * SHADOW, h - 2 * SHADOW
    for i = SHADOW, 1, -2 do
      rounded(cr, x - i / 2, y - i / 2 + 4, cw + i, ch + i, RADIUS + i / 2)
      cairo_set_source_rgba(cr, 0, 0, 0, 0.012)
      cairo_fill(cr)
    end
    rounded(cr, x, y, cw, ch, RADIUS)
    cairo_set_source_rgba(cr, 0.10, 0.10, 0.14, 0.20)
    cairo_fill_preserve(cr)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.10)
    cairo_fill_preserve(cr)
    local sheen = cairo_pattern_create_linear(0, y, 0, y + ch)
    cairo_pattern_add_color_stop_rgba(sheen, 0, 1, 1, 1, 0.16)
    cairo_pattern_add_color_stop_rgba(sheen, 0.5, 1, 1, 1, 0.02)
    cairo_pattern_add_color_stop_rgba(sheen, 1, 1, 1, 1, 0.0)
    cairo_set_source(cr, sheen)
    cairo_fill_preserve(cr)
    cairo_pattern_destroy(sheen)
    cairo_set_line_width(cr, 0.8)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.32)
    cairo_stroke(cr)
  end)
end

-- Calendar like the macOS widget: red month, red circle on today
function conky_calendar()
  with_cairo(function(cr, w, h)
    local left, top = SHADOW + 16, SHADOW + 26
    local inner = w - 2 * SHADOW - 32
    local t = os.date('*t')
    text(cr, string.upper(os.date('%B')), left, top, 10, true, 1, 0.38, 0.35, 1)
    local days = { 'M', 'T', 'W', 'T', 'F', 'S', 'S' }
    local col = inner / 7
    for i, d in ipairs(days) do
      text(cr, d, left + col * (i - 0.5), top + 20, 8, true, 1, 1, 1, 0.5, 'center')
    end
    local first = os.time { year = t.year, month = t.month, day = 1, hour = 12 }
    local offset = (tonumber(os.date('%w', first)) + 6) % 7        -- Monday first
    local ndays = os.date('*t', os.time { year = t.year, month = t.month + 1, day = 0, hour = 12 }).day
    local row_h = 17
    for d = 1, ndays do
      local idx = offset + d - 1
      local cx = left + col * (idx % 7 + 0.5)
      local cy = top + 40 + math.floor(idx / 7) * row_h
      if d == t.day then
        cairo_new_path(cr)
        cairo_arc(cr, cx, cy - 3.5, 8, 0, 2 * math.pi)
        cairo_set_source_rgba(cr, 1, 0.33, 0.30, 0.95)
        cairo_fill(cr)
        text(cr, tostring(d), cx, cy, 9.5, true, 1, 1, 1, 1, 'center')
      else
        local weekend = idx % 7 >= 5
        text(cr, tostring(d), cx, cy, 9.5, false, 1, 1, 1, weekend and 0.5 or 0.9, 'center')
      end
    end
  end)
end

local function ring(cr, cx, cy, radius, pct, r, g, b, label)
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
  cairo_set_line_width(cr, 5)
  cairo_new_path(cr)
  cairo_arc(cr, cx, cy, radius, 0, 2 * math.pi)
  cairo_set_source_rgba(cr, 1, 1, 1, 0.14)
  cairo_stroke(cr)
  pct = math.max(0, math.min(100, pct or 0))
  if pct > 0 then
    local start = -math.pi / 2
    cairo_new_path(cr)
    cairo_arc(cr, cx, cy, radius, start, start + 2 * math.pi * pct / 100)
    cairo_set_source_rgba(cr, r, g, b, 0.95)
    cairo_stroke(cr)
  end
  text(cr, string.format('%d', pct), cx, cy + 5, 14, false, 1, 1, 1, 0.95, 'center')
  text(cr, label, cx, cy + radius + 20, 8, true, 1, 1, 1, 0.55, 'center')
end

-- System widget: CPU / Memory / Disk rings like the macOS Batteries widget
function conky_rings()
  with_cairo(function(cr, w, h)
    local cpu  = tonumber(conky_parse('${cpu cpu0}')) or 0
    local mem  = tonumber(conky_parse('${memperc}')) or 0
    local disk = tonumber(conky_parse('${fs_used_perc /}')) or 0
    local inner = w - 2 * SHADOW
    local cy = SHADOW + 62
    local step = inner / 4
    ring(cr, SHADOW + step * 0.62, cy, 28, cpu,  0.04, 0.52, 1.00, 'CPU')
    ring(cr, SHADOW + step * 1.54, cy, 28, mem,  0.19, 0.82, 0.35, 'MEM')
    ring(cr, SHADOW + step * 2.46, cy, 28, disk, 1.00, 0.62, 0.04, 'DISK')
  end)
end

function conky_calendar_card() conky_card(); conky_calendar() end
function conky_system_card()   conky_card(); conky_rings()    end

-- Big desktop clock: thin translucent digits straight on the wallpaper, no card
function conky_bigclock()
  with_cairo(function(cr, w, h)
    local time = os.date('%H:%M')
    local date = os.date('%A, %B ') .. tonumber(os.date('%d'))
    local x, y = 8, 150
    cairo_select_font_face(cr, 'Inter Display ExtraLight', CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 150)
    -- soft shadow so it reads on light wallpapers
    cairo_move_to(cr, x + 1, y + 3)
    cairo_text_path(cr, time)
    cairo_set_source_rgba(cr, 0, 0, 0, 0.10)
    cairo_fill(cr)
    -- frosted fill: brighter at the top
    cairo_move_to(cr, x, y)
    cairo_text_path(cr, time)
    local g = cairo_pattern_create_linear(0, y - 110, 0, y)
    cairo_pattern_add_color_stop_rgba(g, 0, 1, 1, 1, 0.78)
    cairo_pattern_add_color_stop_rgba(g, 1, 1, 1, 1, 0.50)
    cairo_set_source(cr, g)
    cairo_fill_preserve(cr)
    cairo_pattern_destroy(g)
    cairo_set_line_width(cr, 0.8)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.35)
    cairo_stroke(cr)
    cairo_select_font_face(cr, 'Inter Display Light', CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, 22)
    cairo_move_to(cr, x + 6, y + 40)
    cairo_set_source_rgba(cr, 1, 1, 1, 0.80)
    cairo_show_text(cr, date)
  end)
end
