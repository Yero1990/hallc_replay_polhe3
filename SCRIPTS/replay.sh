#!/bin/bash
#set -u 

function print_the_help {
  echo "USAGE: $0 -r <run_number> -n <num> "
  echo "  OPTIONS: "
  echo "            -m,--mode          Mode: HMS, SHMS or COIN (required)"
  echo "            -r,--run           Run number (required)"
  echo "            -n,--n-events      Number of events (default: all)"
  echo "            -s,--skip          Skip N first events (default: 0)"
  echo "            -a,--all           Store ALL variables (default: not set)"
  echo "            -c,--coin          Run in COIN mode (default: SHMS single-arm mode)"
  exit 1
}

function io_error {
  echo ERROR: cannot create or write to directory $1
  exit -1
}
function ensure_directory {
  echo "Ensuring $1 exists and is writable"
  [[ -d "$1" ]] || mkdir -p $1
  touch $1/.write_check || io_error $1
}

function yes_or_no {
  while true; do
    read -p "$* [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) echo "No entered" ; return 1 ;;
    esac
  done
}

MODE=""
run_number=
n_events=-1
min_event=0
DO_COIN="false"
DO_ALL="false"

if [[ $# -eq 0 ]] ; then
  print_the_help
  exit 
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    -h|--help)
      shift # past argument
      print_the_help
      ;;
    -m|--mode)
      MODE="$2"
      shift
      shift
      ;;
    -r|--run)
      run_number="$2"
      shift # past argument
      shift # past value
      ;;
    -n|--n-events)
      n_events="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--skip)
      min_event="$2"
      shift # past argument
      shift # past value
      ;;
    -a|--all)
      DO_ALL="true"
      shift # past argument
      ;;
    -c|--coin)
      DO_COIN="true"     
      shift # past argument
      ;;
    *)    # unknown option
      #POSITIONAL+=("$1") # save it in an array for later
      echo "unknown option"
      print_the_help
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -z ${run_number} ]] ; then
  echo  " need argument -r <run> "
fi
if [[ ${MODE} != "COIN" ]] && [[ ${MODE} != "SHMS" ]] && [[ ${MODE} != "HMS" ]]; then
  echo "Unkown mode flag: ${MODE}"
  print_the_help
fi


echo "Running ${MODE} replay for run ${run_number}"
echo "Analyzing ${n_events} events starting from event ${min_event}"
if [[ ${MODE} != COIN ]]; then
  if [[ ${DO_COIN} = "true" ]]; then
    echo "Running replay in COIN mode"
  else
    echo "Running replay in SHMS single arm mode"
  fi
fi
if [[ ${DO_ALL} = "true" ]]; then
  echo "Note: storing extended set of variables ('all' mode)"
fi


#if [[ $# -eq 0 ]] ; then
#  print_the_help
#  exit 
#fi

## NOTE: if you change anything here, make sure you make corresponding changes 
## in the replay script
REPLAY_ARGS="${run_number},${n_events},${min_event},${DO_ALL},${DO_COIN}"
if [[ $MODE = "COIN" ]]; then
  REPLAY_ARGS="${run_number},${n_events},${min_event},${DO_ALL}"
fi
REPLAY_CMD="SCRIPTS/PRODUCTION/replay_${MODE,,}.cxx+(${REPLAY_ARGS})"
REPORT_DIR="REPORT_OUTPUT/PRODUCTION"
LOGDIR="logs"
ROOTDIR="ROOTfiles"

ensure_directory ${REPORT_DIR}
ensure_directory ${LOGDIR}
ensure_directory ${ROOTDIR}

hcana -b -q "${REPLAY_CMD}"
