#!/bin/bash

# Create namespaces
ip netns add vr01
ip netns add vr02
ip netns add vr03

# Move interfaces to namespaces
ip link set eth1 netns vr01
ip link set eth2 netns vr02
ip link set eth3 netns vr03

# Configure IP addresses within namespaces
ip netns exec vr01 ip addr add 10.0.0.1/24 dev eth1
ip netns exec vr01 ip link set eth1 up

ip netns exec vr02 ip addr add 192.168.1.1/24 dev eth2
ip netns exec vr02 ip link set eth2 up

ip netns exec vr03 ip addr add 192.168.1.1/24 dev eth3
ip netns exec vr03 ip link set eth3 up

# Create and configure veth interfaces
ip link add vr01-vr02-veth0 type veth peer vr02-vr01-veth0
ip link set vr01-vr02-veth0 netns vr01
ip link set vr02-vr01-veth0 netns vr02

ip netns exec vr01 ip addr add 192.168.12.1/24 dev vr01-vr02-veth0
ip netns exec vr01 ip link set vr01-vr02-veth0 up

ip netns exec vr02 ip addr add 192.168.12.2/24 dev vr02-vr01-veth0
ip netns exec vr02 ip link set vr02-vr01-veth0 up

ip link add vr01-vr03-veth0 type veth peer vr03-vr01-veth0
ip link set vr01-vr03-veth0 netns vr01
ip link set vr03-vr01-veth0 netns vr03

ip netns exec vr01 ip addr add 192.168.13.1/24 dev vr01-vr03-veth0
ip netns exec vr01 ip link set vr01-vr03-veth0 up

ip netns exec vr03 ip addr add 192.168.13.3/24 dev vr03-vr01-veth0
ip netns exec vr03 ip link set vr03-vr01-veth0 up

# Configure routing
ip netns exec vr02 ip route add 10.0.0.0/24 via 192.168.12.1 dev vr02-vr01-veth0
ip netns exec vr03 ip route add 10.0.0.0/24 via 192.168.13.1 dev vr03-vr01-veth0

# Enable IP forwarding (optional, if needed)
ip netns exec vr01 sysctl -w net.ipv4.ip_forward=1
ip netns exec vr02 sysctl -w net.ipv4.ip_forward=1
ip netns exec vr03 sysctl -w net.ipv4.ip_forward=1

# NAT configuration
ip netns exec vr02 iptables -t nat -A PREROUTING -i vns02-veth1 -p icmp -j DNAT --to-destination 192.168.1.100
ip netns exec vr02 iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.1.100:22
ip netns exec vr03 iptables -t nat -A PREROUTING -i vns03-veth1 -p icmp -j DNAT --to-destination 192.168.1.100
ip netns exec vr03 iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.1.100:22
