touch /etc/config/monlor
uci set monlor.tools=config
uci set monlor.tools.userdisk="|||||"
uci commit monlor