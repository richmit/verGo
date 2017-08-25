#!/usr/bin/zsh

# -*- Mode:Shell-script sh-shell:zsh; Coding:us-ascii-unix; fill-column:128 -*-

# Look for links to verGo.sh in the CWD, and see if verGo.sh can resolve the application path

WACK_BAD=N

UNRESOLVED=''
for f in *(@); do
  t=`readlink $f`
  if [ $t = 'verGo.sh' ] ; then
    r=`verGo.sh -app $f -noRun -prtCmd`
    if [ -z "$r" ] ; then
      UNRESOLVED="$f $UNRESOLVED"
      if [ "$WACK_BAD" = 'Y' ] ; then
        rm -f $f
      fi
    fi
  fi
done
if [ -n "$UNRESOLVED" ] ; then
  echo UNRESOLVED VERGO LINKS: $UNRESOLVED
else
  echo ALL VERGO LINKS RESOLVED
fi

