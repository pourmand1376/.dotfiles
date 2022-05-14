# Import our GPG public key
rpm --import https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc

# Add the Anaconda repository
cat <<EOF > /etc/yum.repos.d/conda.repo
[conda]
name=Conda
baseurl=https://repo.anaconda.com/pkgs/misc/rpmrepo/conda
enabled=1
gpgcheck=1
gpgkey=https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc
EOF

dnf install conda
