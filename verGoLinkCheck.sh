#!/bin/bash

# -*- Mode:Shell-script sh-shell:zsh; Coding:us-ascii-unix; fill-column:128 -*-

# Look for links to verGo.sh in the CWD, and see if verGo.sh can resolve the application path

WACK_BAD='N'
VERBOSE='N'

VERGO_SUM=`md5sum verGo.sh | cut -c1-32`

UNRESOLVED=''
for f in *; do
  CHECK_IT='F'
  if [ "$VERBOSE" = 'Y' ] ; then echo "CHECKING: $f"; fi
  if [ -L "$f" ] ; then
    t=`readlink $f`
    if [ $t = 'verGo.sh' ] ; then
      if [ "$VERBOSE" = 'Y' ] ; then echo "  LINK TO CHECK"; fi
      CHECK_IT='T'
    fi
  else
    if [ "$f" != 'verGo.sh' ] ; then
      if [ "$VERGO_SUM" = `md5sum $f | cut -c1-32` ] ; then
        if [ "$VERBOSE" = 'Y' ] ; then echo "  FILE TO CHECK"; fi
        CHECK_IT='T'
      fi
    fi
  fi
  if [ "$CHECK_IT" = 'T' ] ; then
    r=`verGo.sh -app $f -noRun -prtCmd`
    if [ -z "$r" ] ; then
      if [ "$VERBOSE" = 'Y' ] ; then echo "  UNRESOLVED"; fi
      UNRESOLVED="$f $UNRESOLVED"
      if [ "$WACK_BAD" = 'Y' ] ; then
        rm -f $f
      fi
    else
      if [ "$VERBOSE" = 'Y' ] ; then echo "  RESOLVED"; fi
    fi
  else
    if [ "$VERBOSE" = 'Y' ] ; then echo "  NO NEED TO CHECK"; fi
  fi
done
if [ -n "$UNRESOLVED" ] ; then
  echo "UNRESOLVED VERGO LINKS: $UNRESOLVED"
else
  echo "ALL VERGO LINKS RESOLVED"
fi

