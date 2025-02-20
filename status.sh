#!/bin/bash

# Node status monitor

# Matsuro Hadouken <matsuro-hadouken@protonmail.com> 2020
# Contributed By : RapidMark

# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.

# PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

# Requirements: 'apt install jq' 'apt install tree'

# When: Run while syncing, or just in general to see the status and messages coming in

# Commands: Ctrl-C to quit

unit_name="casper-node-launcher"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'
PUB_KEY="$(curl -s localhost:8888/status | jq -r .our_public_signing_key)"

IPv4_STRING='(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'

numba='^[0-9]+$'

theoretically_trusted_ip=$(cat /etc/casper/1_0_0/config.toml | grep 'known_addresses = ' | grep -E -o "$IPv4_STRING")

function watch_unit() {

watch -c SYSTEMD_COLORS=1 "systemctl show casper-node-launcher.service | grep --color=always -e MemoryCurrent \
  -e ActiveState \
  -e LoadState \
  -e FragmentPath \
  -e StateChangeTimestamp= && echo && \
  ps -p $(pidof casper-node-launcher) -o etime && echo && \
  echo -n 'Public signing key: ${GREEN}${PUB_KEY}${NC}' && echo && \
  echo -n 'Local height : $GREEN' && curl -s localhost:8888/status | jq -r .last_added_block_info.height && echo -n '$NC' && \
  echo -n 'Chain height : $GREEN' && curl -s 31.7.207.16:8888/status | jq -r .last_added_block_info.height && echo -n '$NC' && \
  echo -n 'Round length : $GREEN' && curl -s localhost:8888/status | jq -r .round_length && echo -n '$NC' && \
  echo -n 'Next upgrade : $GREEN' && curl -s localhost:8888/status | jq -r '.next_upgrade | "\""Activation ERA: \(.activation_point)\tProtocol: \(.protocol_version)"\""' && echo -n '$NC' && \
  echo -n 'Build version: $GREEN' && curl -s localhost:8888/status | jq -r .build_version && echo -n '$NC' && echo &&\

  echo -n 'Chain name   : $GREEN' && curl -s localhost:8888/status | jq -r .chainspec_name && echo -n '$NC' && \
  echo -n 'Starting hash: $GREEN' && curl -s localhost:8888/status | jq -r .starting_state_root_hash && echo -n '$NC' && echo && \

  echo -n 'API Version  : $GREEN' && curl -s localhost:8888/status | jq -r .api_version && echo -n '$NC' && \
  echo -n 'Local ERA    : $GREEN' && curl -s localhost:8888/status | jq -r .last_added_block_info.era_id && echo -n '$NC' && echo && \

  echo -n 'ERA ' && echo -n $(curl -s localhost:8888/status | jq -r .last_added_block_info.era_id) && echo -n ' weight: $GREEN' && casper-client get-auction-info | jq -r '.result.auction_state.era_validators | .[0].validator_weights[] | select(.public_key=="\""$PUB_KEY"\"")| .weight ' && echo -n '$NC' && \
  echo -n 'ERA ' && echo -n $(( $(curl -s localhost:8888/status | jq -r .last_added_block_info.era_id) + 1 )) && echo -n ' weight: $GREEN' && casper-client get-auction-info | jq -r '.result.auction_state.era_validators | .[1].validator_weights[] | select(.public_key=="\""$PUB_KEY"\"")| .weight ' && echo -n '$NC' && echo && \
  echo -n 'Database folder size: $GREEN' $(du -m /var/lib/casper/casper-node | awk '{print $1;}') && echo -n "M" '$NC' && echo && echo && \
  tree -C -P *lmdb* --noreport -h /var/lib/casper/casper-node && echo && \
  echo -n 'Peers connected: $GREEN' && curl -s localhost:8888/status | jq -r '.peers | length' && echo -n '$NC' && echo && \
  echo -n 'Validator Slots: $GREEN' && cat /etc/casper/1_0_0/chainspec.toml | grep -e validator_slots  | cut -c19- && echo -n '$NC'"

}

watch_unit
