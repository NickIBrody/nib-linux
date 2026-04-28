version "6.5"
summary "Terminal capability database and curses runtime"
homepage "https://invisible-island.net/ncurses/"
build_dep "gcc", "make"
runtime_dep
step "build wide-character ncurses"
step "install terminfo database under /usr/share/terminfo"
step "provide readline-compatible terminal behavior"
