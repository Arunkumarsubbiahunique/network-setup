ip addr add 10.0.0.10/24 dev eth0 
ip link set up eth0
ip route add default via 10.0.0.1 dev eth0
