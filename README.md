# SDNSimulation
An environment to simulate an SDN dataplane by including extra features such redundant links addition, GRE tunnels, and fault injection
This environment allows to set fault scenarios fully customizable for any network topology by keeping a better configuration control on
the interconnections than the existing in current simulation tools such as Mininet

This This module has several features compared to Mininet, such as:
-the full customization of the interconnections between switches, hosts, and controller(s) with single, redundant links, and alternative paths,
-the addition in real-time of new nodes to the topology,
-the connection of virtual machines embedding simple
topologies with GRE tunnels, and
-the addition of several controllers to control different
groups of switches

This module receives the real-time topological information through the northbound API of the SDN controller. If a new node appears in the topology, the module incorporates it with all its related information. The GUI of the fault injection module is shown in Fig. 1 (b).
The fault injection module allows us to disconnect any port in the OVS switches, disconnect a switch from the controller and to reduce the bandwidth on any of those ports.



#File description
1) transmitter.sh --> sends a video using VLC media with UDP through port 1234 to IP_DESTINATION (transmitter.sh IP_DEST)
2) receiver.sh  --> receives the video content
3) topo_v4.sh --> topology generation using OVS and namespaces. Example of use for 5 OVS switches :
Example: sudo bash topo_v4.sh -r -s "s1 s2 s3 s4 s5" -l "s1-s2 s2-s3 s3-s4 s3-s1 s2-s5 s5-s3" -c "192.168.56.104" -h "h1 h2" -sh "s1-h1 s2-h2" -g "s1-192.168.56.102-192.168.56.101"
4) FaultScenarios_v4.py --> GUI to inject faults and capture traffic
5) FaultScenarios_v4_support.py -->those functions defined to support the GUI
