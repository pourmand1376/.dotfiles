# I tested this on fedora 35 and manjaro.

sudo mkdir -p /etc/docker
echo '{                                                                                           ✔  17:27:50 
    "registry-mirrors": ["https://registry.docker.ir"]
}' | sudo tee /etc/docker/daemon.json
sudo systemctl daemon-reload
sudo systemctl restart docker

# docker without sudo 
sudo groupadd docker
sudo usermod -aG docker $USER

 sudo systemctl enable docker.service
 sudo systemctl enable containerd.service