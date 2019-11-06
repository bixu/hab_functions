#!/bin/sh

CENSUS_ENDPOINT="http://localhost:9631/census"
HAB_BINARY=hab

# Helper function to display usage information
__hf_usage() {
  echo ""
  echo "Usage: ${1}"
  echo ""
}

hab_functions_setup() {
  ${HAB_BINARY} pkg install --binlink core/curl
  ${HAB_BINARY} pkg install --binlink core/jq-static
}

# Display service group leaders
service_group_leaders() {
  if [ -z ${1} ]; then
    __hf_usage "${FUNCNAME[0]} <'service.group'> ['ssh user@host']"
    return 1
  fi
  service_group="${1}"

  census_data_command="curl --silent ${CENSUS_ENDPOINT}"
  if [ ! -z ${2} ]; then
    census_data_command="${2} ${census_data_command}"
  fi

  census_data="$(${census_data_command})"
  leader_data="$(echo "${census_data}" | \
    jq -r ".census_groups | select(.\"${service_group}\" != null) | .[] | .population | .[] | select(.leader == true)")"

  echo "$(echo $leader_data | \
    jq -r '
    "\nHostname: " + "\(.sys | .hostname)" +
    "\nAddress: "  + "\(.sys | .ip)" +
    "\nAlive: "    + "\(.alive)" +
    "\nLeader: "   + "\(.leader)" +
    "\nDeparted: " + "\(.departed)" +
    "\nMemberID: " + "\(.member_id)" + "\n======"')" | column -t
}

service_group_members() {
  if [ -z ${1} ]; then
    __hf_usage "${FUNCNAME[0]} <'service.group'> ['ssh user@host']"
    return 1
  fi
  service_group="${1}"

  census_data_command="curl --silent ${CENSUS_ENDPOINT}"
  if [ ! -z ${2} ]; then
    census_data_command="${2} ${census_data_command}"
  fi

  census_data="$(${census_data_command})"
  member_data="$(echo "${census_data}" | \
    jq -r ".census_groups | select(.\"${service_group}\" != null) | .[] | .population | .[] | select(.alive == true)")"

  echo "$(echo $member_data | \
    jq -r '
    "\nHostname: " + "\(.sys | .hostname)" +
    "\nLeader:   " + "\(.leader)" +
    "\nDeparted: " + "\(.departed)" +
    "\nMemberID: " + "\(.member_id)" + "\n======"')" | column -t
}

depart_member() {
  if [ -z $2 ]; then
    __hf_usage "${FUNCNAME[0]} <'member id'> <'ssh user@host'>"
    return 1
  fi
  ${2} "sudo ${HAB_BINARY} sup depart ${1}"
}
