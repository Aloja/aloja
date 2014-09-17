#common bash variables and functions across ALOJA
#must be sourced

#common variables
testKey="###OK###"

#common funtions
logger() {
  dateTime="$(date +%Y%m%d_%H%M%S)"
  echo "$dateTime: $1"
}

#trasposes new lines to selected string
#$1 string to traspose $2 traspose
nl2char() {
  tmp="$(echo -e "$1"|tr "\n" "$2")"
  echo "${tmp::-1}" #remove trailing $2
}