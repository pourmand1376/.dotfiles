sudo dnf install python3-evdev python3-devel gtksourceview4 python3-pydantic
sudo dnf install python-pydbus
sudo dnf install xmodmap

sudo pip install evdev -U
git clone https://github.com/sezanzeb/input-remapper.git
cd input-remapper
sudo python3 setup.py install
sudo systemctl enable input-remapper
sudo systemctl restart input-remapper

