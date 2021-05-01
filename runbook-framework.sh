# Runbook Framework
# See github.com/deweysasser/runbook-framework

set -ueo pipefail

# run or doc?
_mode="run"
_verbose=false

_stepnumber=0
_status=0

_red=1
_green=2

# A temporary directory
_tmp="/tmp/$(basename "$0")-runbook-$$"
trap 'rm -rf $_tmp' EXIT
mkdir -p "$_tmp"

# the main event
main() {
  local params
  while [ -n "$*" ]; do
    case $1 in
    -doc) _mode="doc" ;;
    -h | -help)
      help
      exit 0
      ;;
    -v | -verbose) _verbose=true ;;
    --*) params+=("$1") ;;
    esac
    shift
  done

  if ! _has_all_parameters "${params[@]}"; then
    help
    exit 1
  fi

  _set_parameters "${params[@]}"

  runbook
}

# A runbook step
step() {
  doc="$1"
  shift
  _stepnumber=$((_stepnumber + 1))
  if [ "$_mode" == "doc" ]; then
    echo "${_stepnumber}: $doc"
    return
  fi

  local start
  start=$(date +%s)

  if [ -n "$*" ]; then
    printf "%2d: (%s) %s..." $_stepnumber "$(date +%H:%M)" "$doc"

    if _run "$@"; then
      printf " (%d s) " $(($(date +%s) - start))
      _green 'DONE'
      $_verbose && _show_output $_green $_stepnumber
    else
      _status=$((_status + 1))
      printf " (%d s) " $(($(date +%s) - start))
      _red "FAILED"
      _show_output $_red $_stepnumber
      exit $_status
    fi
  else
    printf "%2d: (%s) %s...(press enter when done)" $_stepnumber "$(date +%H:%M)" "$doc"
    read -r -s
    printf " (%d s) " $(($(date +%s) - start))
    _green 'DONE'
  fi

  _status+=0
}

# show the output from the last step
_show_output() {
  local color=$1
  local number=$2
  local c n
  c=$(tput setaf "$color")
  n=$(tput sgr0)

  awk "{print \"    $c>>$n \" \$0}" <"${_tmp}/step-${number}.txt"
}

_green() {
  _echoColor $_green "$@"
}

_red() {
  _echoColor $_red "$@"
}

_echoColor() {
  tput setaf "$1"
  shift
  echo "$@"
  tput sgr0
}

# Execute the passed in command and arrange for the output to display only if failed
_run() {
  if eval "$@" >"${_tmp}/step-${_stepnumber}.txt" 2>&1; then
    return 0
  else
    return 1
  fi
}

# Set the parameters required by the script
parameters() {
  _parameters=("$*")
}

# Set parameters into the environment
_set_parameters() {
  local name arg
  for arg in "$@"; do
    case $arg in
    --*)
      name="${arg/=*/}"
      name="${name/--/}"
      value="${arg/--*=/}"
      eval "$name='${value}'"
      ;;
    esac
  done
}

# Check to see if all parameters are set
_has_all_parameters() {
  local param ret paramsSet p arg
  declare -A paramsSet

  for arg in "$@"; do
    case $arg in
    --*)
      p="${arg/=*/}"
      p="${p/--/}"
      paramsSet[$p]=true
      ;;
    esac
  done

  ret=0
  for param in ${_parameters[*]}; do
    if [ -z "${!param:-}" ] && [ -z "${paramsSet[$param]:-}" ]; then
      ret=1
      echo "Parameter '$param' required"
    fi
  done

  return $ret
}

# Display help about the runbook
help() {
  local parameters="" param has_defaults=0
  #  local docs=_extract_runbook_doc
  for param in ${_parameters[*]}; do
    if [ -z "${!param:-}" ]; then
      parameters="${parameters}--${param}=VALUE "
    else
      has_defaults=1
      parameters="[${parameters}--${param}=VALUE] "
    fi
  done
  cat <<EOF
Usage: $0 [-h|-help] [-show] $parameters
EOF
  if [ $has_defaults == 1 ]; then
    echo "Defaults:"
    for param in ${_parameters[*]}; do
      if [ -n "${!param:-}" ]; then
        echo "  " "$param" = "${!param}"
      fi
    done
  fi
}

# Extract the documentation block
_extract_runbook_doc() {
  echo ""
}
