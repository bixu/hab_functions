#!/bin/bash

service_group_leaders() {
  if [ -z $2 ]
  then
    echo ""
    echo "usage: ${FUNCNAME[0]} '<ssh user@host>' '<service.group>'"
    echo ""
    return 1
  fi

  ssh_command=$1
  service_group=$2

  census_data=$($ssh_command 'curl --silent localhost:9631/census')
  leader_data=$(echo $census_data | jq -r ".census_groups | .\"$service_group\" | .population | .[] | select(.leader == true)")

  echo "$(echo $leader_data | jq -r '
                              "\nHostname: " + "\(.sys | .hostname)" +
                              "\nAddress: "  + "\(.sys | .ip)" +
                              "\nAlive: "    + "\(.alive)" +
                              "\nLeader: "   + "\(.leader)" +
                              "\nDeparted: " + "\(.departed)" +
                              "\nMemberID: " + "\(.member_id)" + "\n======"')" | column -t
}

service_group_members() {
  if [ -z $2 ]
  then
    echo ""
    echo "usage: ${FUNCNAME[0]} '<ssh user@host>' '<service.group>'"
    echo ""
    return 1
  fi

  ssh_command=$1
  service_group=$2

  census_data=$($ssh_command 'curl --silent localhost:9631/census')
  leader_data=$(echo $census_data | jq -r ".census_groups | .\"$service_group\" | .population | .[] | select(.alive == true)")

  echo "$(echo $leader_data | jq -r '
                              "\nHostname: " + "\(.sys | .hostname)" +
                              "\nLeader: "   + "\(.leader)" +
                              "\nDeparted: " + "\(.departed)" +
                              "\nMemberID: " + "\(.member_id)" + "\n======"')" | column -t
}

depart_member() {
  if [ -z $2 ]
  then
    echo ""
    echo "usage: ${FUNCNAME[0]} '<ssh user@host>' '<member id>'"
    echo ""
    return 1
  fi
  $1 "sudo hab sup depart $2"
}
