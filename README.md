# SDNSimulation
An environment to simulate an SDN dataplane by including extra features and fault injection
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
