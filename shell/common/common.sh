#common bash variables and functions across ALOJA
#must be sourced

#common variables
testKey="###OK###"

#common funtions
logger() {
  dateTime="$(date +%Y%m%d_%H%M%S)"
  echo "$dateTime: $1"
}