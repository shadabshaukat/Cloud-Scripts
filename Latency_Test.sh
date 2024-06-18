#!/bin/bash
#Checks Network Latency to your RDS Instance by running TCPTRACEROUTE 100 times and displays the Network Latency in ms
RED='\033[31m' # <-- Red Color
NC='\033[0m' # No Color
for i in {1..100}; do echo -e "${RED}##### Pass $i #####${NC}" ; sudo tcptraceroute $1 $2 | grep --color=always '<syn,ack>' ; sleep 1; echo -e "${RED}##################${NC}"; echo "" ; done
