#!/usr/bin/env bash

rundir="$1"
pgen="rt_vlasov_sr_twostream_1x1v.lua"

if [ -d "$rundir" ]; then
  rm -rf "$rundir"
fi
mkdir -p "$rundir" &&
  cp "$pgen" "$rundir/" &&
  cd "$rundir" &&
  mpiexec -np 8 ~/gkylsoft/gkylzero/bin/gkyl "$pgen"
