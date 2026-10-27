#!/usr/bin/env bash
# Lich thang tieng Viet, bat dau tu Thu Hai, to mau ngay hom nay.
exec python3 -I - <<'PY'
import calendar, datetime
t = datetime.date.today()
print("${color1}Tháng %d, %d${color}" % (t.month, t.year))
print("${color2}T2 T3 T4 T5 T6 T7 CN${color}")
for week in calendar.Calendar(0).monthdayscalendar(t.year, t.month):
    cells = []
    for d in week:
        if d == 0:
            cells.append("  ")
        elif d == t.day:
            cells.append("${color3}%2d${color}" % d)
        else:
            cells.append("%2d" % d)
    print(" ".join(cells))
PY
