# I tested this on fedora 35 and manjaro and ubuntu

sudo mkdir -p /etc/docker

## for not coflicting with sharif dhcp 
echo '{
	"registry-mirrors": ["https://registry.docker.ir"],
	"bip": "10.10.2.1/24",
	"ipv6": false
}' | sudo tee /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker

# docker without sudo 
sudo groupadd docker
sudo usermod -aG docker $USER

sudo systemctl enable docker.service
sudo systemctl enable containerd.service
