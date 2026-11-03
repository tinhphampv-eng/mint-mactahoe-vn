#!/usr/bin/env python3
# Widget nut nguon kieu macOS 26: Khoa, Ngu, Dang xuat, Khoi dong lai, Tat may.
# Cung kieu the kinh voi cac widget conky (widgets.lua). Giu Alt + keo de di chuyen.
# Bam nut nao cung hoi xac nhan truoc (tru Khoa).
import os
import subprocess
import sys
import math

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk  # noqa: E402

SHADOW = 12
RADIUS = 24
CARD_W, CARD_H = 376, 96
TITLE = 'mactahoe-power'


def sleep_allowed():
    """Module nosleep mask suspend.target: khi do an nut Ngu."""
    try:
        out = subprocess.run(['systemctl', 'is-enabled', 'suspend.target'],
                             capture_output=True, text=True, timeout=3).stdout.strip()
        return out != 'masked'
    except Exception:
        return True


# nhan | icon | lenh | can hoi xac nhan
ACTIONS = [
    ('Khoá', 'system-lock-screen-symbolic', ['xflock4'], False),
    ('Ngủ', 'weather-clear-night-symbolic', ['systemctl', 'suspend'], True),
    ('Đăng xuất', 'system-log-out-symbolic', ['xfce4-session-logout', '--logout'], True),
    ('Khởi động lại', 'system-reboot-symbolic', ['xfce4-session-logout', '--reboot'], True),
    ('Tắt máy', 'system-shutdown-symbolic', ['xfce4-session-logout', '--halt'], True),
]

CSS = b"""
window, .card { background: transparent; }
button.pw {
  min-width: 46px; min-height: 46px; padding: 0; border-radius: 23px;
  border: 1px solid rgba(255,255,255,0.18);
  background: rgba(255,255,255,0.16); box-shadow: none; color: #ffffff;
}
button.pw:hover  { background: rgba(255,255,255,0.30); }
button.pw:active { background: rgba(255,255,255,0.42); }
button.pw.danger:hover { background: rgba(255,69,58,0.85); border-color: rgba(255,69,58,0.9); }
button.pw image { color: #ffffff; -gtk-icon-shadow: none; }
label.pw { color: #ffffff; font-family: Inter; font-size: 9pt; }
"""


def rounded(cr, x, y, w, h, r):
    cr.new_sub_path()
    cr.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    cr.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    cr.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    cr.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    cr.close_path()


class PowerWidget(Gtk.Window):
    def __init__(self):
        super().__init__(title=TITLE)
        self.set_wmclass(TITLE, 'Conky')
        self.set_decorated(False)
        self.set_keep_below(True)
        self.stick()
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_resizable(False)
        self.set_app_paintable(True)
        visual = self.get_screen().get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
        self.set_default_size(CARD_W + 2 * SHADOW, CARD_H + 2 * SHADOW)
        self.connect('draw', self.on_draw)
        self.connect('destroy', Gtk.main_quit)

        row = Gtk.Box(spacing=0, homogeneous=True)
        row.set_margin_start(SHADOW + 10)
        row.set_margin_end(SHADOW + 10)
        row.set_margin_top(SHADOW + 10)
        row.set_margin_bottom(SHADOW + 6)
        can_sleep = sleep_allowed()
        for label, icon, cmd, ask in ACTIONS:
            if cmd[:2] == ['systemctl', 'suspend'] and not can_sleep:
                continue
            row.pack_start(self.make_button(label, icon, cmd, ask), True, True, 0)
        self.add(row)

    def make_button(self, label, icon, cmd, ask):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        btn = Gtk.Button()
        btn.get_style_context().add_class('pw')
        if cmd[-1] in ('--halt', '--reboot'):
            btn.get_style_context().add_class('danger')
        btn.set_image(Gtk.Image.new_from_icon_name(icon, Gtk.IconSize.LARGE_TOOLBAR))
        btn.set_tooltip_text(label)
        btn.set_halign(Gtk.Align.CENTER)
        btn.connect('clicked', self.on_click, label, cmd, ask)
        lbl = Gtk.Label(label=label)
        lbl.get_style_context().add_class('pw')
        box.pack_start(btn, False, False, 0)
        box.pack_start(lbl, False, False, 0)
        return box

    def on_click(self, _btn, label, cmd, ask):
        if ask:
            dlg = Gtk.MessageDialog(transient_for=self, modal=True,
                                    message_type=Gtk.MessageType.QUESTION,
                                    buttons=Gtk.ButtonsType.NONE,
                                    text=f'{label} ngay bây giờ?')
            dlg.format_secondary_text('Hãy lưu công việc đang mở trước khi tiếp tục.')
            dlg.add_buttons('Huỷ', Gtk.ResponseType.CANCEL, label, Gtk.ResponseType.OK)
            dlg.set_default_response(Gtk.ResponseType.CANCEL)
            dlg.set_keep_above(True)
            ok = dlg.run() == Gtk.ResponseType.OK
            dlg.destroy()
            if not ok:
                return
        try:
            subprocess.Popen(cmd, start_new_session=True)
        except FileNotFoundError:
            print(f'Khong tim thay lenh: {cmd[0]}', file=sys.stderr)

    def on_draw(self, _w, cr):
        # Xoa nen, ve the kinh giong conky_card trong widgets.lua
        cr.set_operator(0)  # CLEAR
        cr.paint()
        cr.set_operator(2)  # OVER
        x, y, cw, ch = SHADOW, SHADOW - 2, CARD_W, CARD_H
        for i in range(SHADOW, 0, -2):
            rounded(cr, x - i / 2, y - i / 2 + 4, cw + i, ch + i, RADIUS + i / 2)
            cr.set_source_rgba(0, 0, 0, 0.012)
            cr.fill()
        rounded(cr, x, y, cw, ch, RADIUS)
        cr.set_source_rgba(0.10, 0.10, 0.14, 0.20)
        cr.fill_preserve()
        cr.set_source_rgba(1, 1, 1, 0.10)
        cr.fill_preserve()
        import cairo
        sheen = cairo.LinearGradient(0, y, 0, y + ch)
        sheen.add_color_stop_rgba(0, 1, 1, 1, 0.16)
        sheen.add_color_stop_rgba(0.5, 1, 1, 1, 0.02)
        sheen.add_color_stop_rgba(1, 1, 1, 1, 0.0)
        cr.set_source(sheen)
        cr.fill_preserve()
        cr.set_source_rgba(1, 1, 1, 0.22)
        cr.set_line_width(1)
        cr.stroke()
        return False


def main():
    provider = Gtk.CssProvider()
    provider.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider,
                                             Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    win = PowerWidget()
    win.show_all()
    if len(sys.argv) == 3:
        win.move(int(sys.argv[1]), int(sys.argv[2]))
    Gtk.main()


if __name__ == '__main__':
    main()
