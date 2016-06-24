sudo yum -y install unzip
curl -L -O https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip 2&>1 > /dev/null
unzip consul_0.6.4_linux_amd64.zip
sudo mv consul /usr/local/bin
