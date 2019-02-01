#!/bin/bash

##
## Example: sudo bash topo_v4.sh -r -s "s1 s2 s3 s4 s5" -l "s1-s2 s2-s3 s3-s4 s3-s1 s2-s5 s5-s3" -c "192.168.56.104" -h "h1 h2" -sh "s1-h1 s2-h2" -g "s1-192.168.56.102-192.168.56.101"
##

function create_host {

for h in $1
#declaring the host, each with a private IP (40.0.X.Y) which is random an a identifier (h1, h2, etc.)

do
	hostports[$h]=0
	#echo $h
	ip netns add $h #names of hosts 1,2,...
	ipaddress=$(echo $((40)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)))
	hosts+=([$h]=$ipaddress)
	printf "$h\n" >> host_name.txt
	printf "${hosts[$h]}\n" >> host_ip.txt; 
done
}

function remove_host { #PENDING PROBLEMA EN EL FICHERO IP BORRA TODO O BORRA MAS DE UNA LINEA
	ip netns del $1 #names of hosts 1,2,... #delete namespace
	
	line_host=$(grep -n $1 host_name.txt | head -n 1 | cut -d ":" -f1) #ALL HOSTS ARE ORDERED BY NAME
	#printf $line_host #find the line where the host was
	sudo sed -i"" "/$line_host/d" host_name.txt #correct	
	sudo sed -i"" -e ''$line_host'd' host_ip.txt #correct
	
	#lines_switch_host_link=$(grep -n $1 switch_host_link.txt | cut -d ":" -f1) #linea donde esta implicado el host
	sudo sed -i"" "/$1/d" switch_host_link.txt #que empiece por sX (LO REVIENTA)
	sudo sed -i"" "/$1/d" switch_host.txt #que empiece por sX
	sudo sed -i"" "/$1/d" host_switch.txt #que empiece por sX (correcta)
}

function remove_switch {
	ovs-vsctl del-br $1 #delete switch (bridge)
	
	line_switch=$(grep -n $1 switch_name.txt | head -n 1 | cut -d ":" -f1)
	#printf $line_switch #find the line where the switch was
	sudo sed -i"" "/$line_switch/d" switch_name.txt #correct
	sudo sed -i"" -e ''$line_switch'd' switch_dpid.txt
	sudo sed -i"" -e ''$line_switch'd' switch_controller_ip.txt
	sudo sed -i"" -e ''$line_switch'd' switch_controller.txt
	sudo sed -i"" -e ''$line_switch'd' switch_tcp_port.txt
	
	#lines_switch_host_link=$(grep -n $1 switch_host_link.txt | cut -d ":" -f1) #linea donde esta implicado el host
	sudo sed -i"" "/$1/ d" switch_host_link.txt #que empiece por sX
	sudo sed -i"" "/$1/ d" switch_host.txt #que empiece por sX
	sudo sed -i"" "/$1/ d" controller_switch.txt #que empiece por sX
	
	#lines_switch_link=$(grep -n $1 switch_link.txt | cut -d ":" -f1) #linea donde esta implicado el host
	sudo sed -i"" "/$1/ d" switch_link.txt #que empiece por sX
}


#PENDING
function create_switch {

#datapathID_integer=1 #must start by 0000000000000001

for s in $1
	do	
		datapathID_integer=${s#?} #take the integer of the name 's1-->1' and convert it to hexadeicmal
		datapathID=$(printf "%016x\n" $datapathID_integer)
		
		#write the ip of the SDN controller of that switch	
		switch_controller_ip+=([$s]=$2) # ip address is the second parameter when the function is called
		switch_controller+=([$s]=$s'-'$2) # ip address is the second parameter when the function is called

		printf "${switch_controller_ip[$s]}\n" >> switch_controller_ip.txt; 
		printf "${switch_controller[$s]}\n" >> switch_controller.txt; 

		switchports[$s]=1
		ovs-vsctl add-br $s	
		printf "$s\n" >> switch_name.txt # add the name of the switch

		ovs-vsctl set Bridge $s other-config:datapath-id=$datapathID #writing the DPID on the switch
		printf "$datapathID\n" >> switch_dpid.txt; #PENDING
		ifconfig $s up

		ovs-vsctl set-controller $s tcp:$2 #now the TCP port appears (PENDING: THE SDN CONTROLLER IS NOT CONNECTED TO THE SWITCHES)
		ovs-vsctl set-fail-mode $s secure
		ovs-vsctl set controller $s connection-mode=$3
		if [ "$3" == "out-of-band" ]; then
			
			ovs-vsctl set bridge $s other-config:disable-in-band=true	
		fi 
		
		#if [ "$datapathID_integer" -eq 1 ]; then
		#	data_plane_ip=$(netstat | grep 6633 | awk '{print $4}' | tail -1 | cut -d ":" -f1);
		#fi
		
		#sudo ovs-vsctl get Bridge s1 datapath-id #PENDING TO CREATE  FILE WITH DATAPATH OF EACH SWITCH ( format switch_name, switch DPID, tcp port)
		tcp_port=$(netstat | grep 6633 | awk '{print $4}' | sort | tail -1 | cut -d ":" -f2) # te quedas con el puerto solamente de la ultima linea (se muestran crecientemente asi que es el ultimo)	
		#printf "$tcp_port\n"
		switch_tcp_ports+=([$s]=$tcp_port) #get the port of that line (192.168.30.1:59482)
		printf "${switch_tcp_ports[$s]}\n" >> switch_tcp_port.txt; 
		# tarda tiempo en desaparecer por completo los puertos (pending )
	done

#echo $data_plane_ip
}



function create_link {
for l in $1
do
	#echo $l
	x1=$(echo $l | cut -d "-" -f1)
		x2=$(echo $l | cut -d "-" -f2)
	#echo $x1
	#echo $x2

	#######
	### USING PATCH INTERFACES
	#######
	#ovs-vsctl add-port $x1 $x1-$x2 -- set Interface $x1-$x2 type=patch options:peer=$x2-$x1
	#ovs-vsctl add-port $x2 $x2-$x1 -- set Interface $x2-$x1 type=patch options:peer=$x1-$x2

	#######
	### USING VETH INTERFACES
	#######
	ip li add $x1-$x2 type veth peer name $x2-$x1
	ovs-vsctl add-port $x1 $x1-$x2
	ovs-vsctl add-port $x2 $x2-$x1
	ifconfig $x1-$x2 up
	ifconfig $x2-$x1 up
	echo $x1-$x2 >> switch_link.txt
	echo $x2-$x1 >> switch_link.txt
done
}

function create_redundant_link {
for l in $1
do

	x1=$(echo $l | cut -d "-" -f1)
		x2=$(echo $l | cut -d "-" -f2)
			x3=$(echo $l | cut -d "-" -f3)
	#echo $x1 $x2 $x3
	#######
	### USING PATCH INTERFACES
	#######
	#ovs-vsctl add-port $x1 $x1-$x2 -- set Interface $x1-$x2 type=patch options:peer=$x2-$x1
	#ovs-vsctl add-port $x2 $x2-$x1 -- set Interface $x2-$x1 type=patch options:peer=$x1-$x2

	#######
	### USING VETH INTERFACES
	#######
	for((k=0; k<$x1;k++));
	do
		#echo $k
		ip li add $x2-$x3-$x1-$k type veth peer name $x3-$x2-$x1-$k
		ovs-vsctl add-port $x2 $x2-$x3-$x1-$k
		ovs-vsctl add-port $x3 $x3-$x2-$x1-$k
		ifconfig $x2-$x3-$x1-$k up
		ifconfig $x3-$x2-$x1-$k up
		echo $x2-$x3-$x1-$k >> switch_link.txt
		echo $x3-$x2-$x1-$k >> switch_link.txt
	done

done
}


function create_lsh {

#declare -i it
for l in $1
do
	echo $l >> switch_host_link.txt
	x1=$(echo $l | cut -d "-" -f1)
		x2=$(echo $l | cut -d "-" -f2)
	declare -i seth=${switchports[$x1]}
	declare -i heth=${hostports[$x2]}
	#echo $x1 "switch" $seth
	ip link add $x2-eth$heth type veth peer name $x1-eth$seth
	ip link set $x2-eth$heth netns $x2
	#ip netns exec $x2 ip link show
	MAC_integer=$x2 #take the integer of the name 's1-->1' and convert it to hexadeicmal
	MAC_integer=${MAC_integer:1:2}
	MAC_ID=$(printf "%012x\n" $MAC_integer)
	
	MAC_ID=${MAC_ID:0:1}${MAC_ID:1:1}":"${MAC_ID:2:1}${MAC_ID:3:1}":"${MAC_ID:4:1}${MAC_ID:5:1}":"${MAC_ID:6:1}${MAC_ID:7:1}":"${MAC_ID:8:1}${MAC_ID:9:1}":"${MAC_ID:10:1}${MAC_ID:11:1}
	ip netns exec $x2 ifconfig $x2-eth$heth hw ether $MAC_ID
	printf "$MAC_ID\n" >> host_mac.txt
	ovs-vsctl add-port $x1 $x1-eth$seth


	ip netns exec $x2 ifconfig $x2-eth$heth "${hosts[$x2]}" ##Warning: to change in the script on the cibling machine
	ip netns exec $x2 ifconfig lo up
	ifconfig $x1-eth$seth up
	#echo $x1-eth$seth up
	echo $x1-eth$seth >> switch_host.txt
	echo $x2-eth$heth >> host_switch.txt
	it=$((it+1))
	seth=$((seth+1))
	heth=$((heth+1))
	switchports[$x1]=$seth
	hostports[$x2]+=$heth
done
}


# Tunnel gre to connect with another machine, eg. -g "s1-IP_LOCAL-IP_DST"
function create_tunnel {

	x1=$(echo $1 | cut -d "-" -f1)
		x2=$(echo $1 | cut -d "-" -f2)
			x3=$(echo $1 | cut -d "-" -f3)
	
	ip li ad $x1-gre type gretap local $x2 remote $x3 ttl 64
	ip li se dev $x1-gre up
	ovs-vsctl add-port $x1 $x1-gre
	
	#ovs-vsctl add-port $x1 $x1-gre -- set interface $x1-gre type=gre options:remote_ip=$x2
}

function del_topo {

	> host_name.txt
	> host_mac.txt
	> host_ip.txt
	> host_switch.txt

	> controller_type.txt
	> controller_state.txt
	
	> switch_tcp_port.txt
	> switch_dpid.txt
	> switch_name.txt
	> switch_link.txt
	> switch_host.txt
	> switch_host_link.txt
	> switch_controller_ip.txt
	> switch_controller.txt

	#> controllers.txt

	domaine=($(ip  netns)) #Warning: may change depending on the kernel distribution
	for dom in "${domaine[@]}"
	do
		ip netns delete $dom
	done

	tun=($(((ip li | grep "\-[gre]") | cut -d "@" -f1) | cut -d " " -f2))

	for tunt in "${tun[@]}"
	do	
		ip li del $tun #may have problems when deleting the tuntap interface, recommended to run several times before execution a new topology
	done
	
	switches=($(ovs-vsctl list-br))
	for s in "${switches[@]}"
	do
		ovs-vsctl del-br $s
	done

	interfaces_switch=($(((ip li | grep s[0-9]) | cut -d "@" -f1) | cut -d " " -f2))
	for i in "${interfaces_switch[@]}"
	do
		ip li del $i
	done
}

#function set_controller {
#	switches=($(ovs-vsctl list-br)) #takes all the switches
#	for s in "${switches[@]}" #for each switch
#	do
#		ovs-vsctl set-controller $s tcp:$1
#		ovs-vsctl set-fail-mode $s secure
#		#ovs-vsctl set controller $s connection-mode=out-of-band
#	done
#
#	echo $1 >> controllers.txt
#	#write a file with the ip of the controller and the port to the switch
#}

function set_cluster {
	x1=$(echo $1 | cut -d " " -f1)
	x2=$(echo $1 | cut -d " " -f2)
	x3=$(echo $1 | cut -d " " -f3)
	switches=($(ovs-vsctl list-br))
	for s in "${switches[@]}"
	do
		ovs-vsctl set-controller $s tcp:$x1 tcp:$x2 tcp:$x3
		ovs-vsctl set-fail-mode $s secure
	done

	echo $x1 >> controllers.txt
	echo $x2 >> controllers.txt
	echo $x3 >> controllers.txt
}

declare -Ai switchports
declare -Ai hostports

declare -A hosts
declare -A switch_tcp_ports
declare -A switch_controller_ip 
declare -A switch_controller

array_arg=("$@")

for((n=0; $n<$# ; n++))
	
do

	case ${array_arg[$n]} in
		"-h") create_host "${array_arg[$((n+1))]}";;
		"-rh") remove_host "${array_arg[$((n+1))]}";;
		"-rs") remove_switch "${array_arg[$((n+1))]}";;
		"-s") create_switch "${array_arg[$((n+1))]}" "${array_arg[$((n+2))]}" "${array_arg[$((n+3))]}";;
		"-l") create_link "${array_arg[$((n+1))]}";;
		"-ld") create_redundant_link "${array_arg[$((n+1))]}";;
		"-sh") create_lsh "${array_arg[$((n+1))]}";;
		"-g") create_tunnel "${array_arg[$((n+1))]}";;
		"-c") set_controller "${array_arg[$((n+1))]}";; #not useful
		"-cl") set_cluster "${array_arg[$((n+1))]}";;
		"-r") del_topo;;
		"-m") model="${array_arg[$((n+1))]}";;

	esac
done



