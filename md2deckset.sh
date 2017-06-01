#!/bin/bash

usage() { echo "Usage: $0 <source.md> <presentation.md>" 1>&2; exit 1; }
src=$1
presentation=$2

if [ -z "${src}" ] || [ -z "${presentation}" ]; then
  usage
fi

cat $src | sed 's/<!-- slide -->/---/g' > ${presentation}
