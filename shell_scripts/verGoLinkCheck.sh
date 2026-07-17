#!/usr/bin/env -S sh
# -*- Mode:Shell-script; Coding:us-ascii-unix; fill-column:158 -*-
#########################################################################################################################################################.H.S.##
##
# @file      verGoLinkCheck.sh
# @author    Mitch Richling http://www.mitchr.me/
# @date      2024-09-21
# @brief     Verify links/copies to/of verGo.sh in the current working directory.@EOL
# @std       bash
# @see       
# @copyright 
#  @parblock
#  Copyright (c) 2024, Mitchell Jay Richling <http://www.mitchr.me/> All rights reserved.
#  
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#  
#  1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
#  
#  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  
#  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#  
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
#  DAMAGE.
#  #  @endparblock
#########################################################################################################################################################.H.E.##

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
WACK_BAD='N'
VERBOSE='N'
VERGOBIN='verGo.sh'
while [ -n "$1" ] ; do
  case "$1" in
    -p   )                                     shift; ;;
    -d   ) WACK_BAD='Y';                       shift; ;;
    -v   ) VERBOSE='Y';                        shift; ;;
    -b   ) shift; VERGOBIN="$1";               shift; ;;
    *    ) echo "Unknown argument: $1"; exit;         ;;
  esac
done

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
VERGO_SUM=`md5sum "$VERGOBIN" | cut -c1-32`

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
UNRESOLVED=''
for f in *; do
  CHECK_IT='F'
  if [ "$VERBOSE" = 'Y' ] ; then echo "CHECKING: $f"; fi
  if [[ "$f" != *.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] ]]; then
    if [ -L "$f" ] ; then
      t=`readlink $f`
      if [ $t = 'verGo.sh' ] ; then
        if [ "$VERBOSE" = 'Y' ] ; then echo "  LINK TO CHECK"; fi
        CHECK_IT='T'
      fi
    elif [ -f "$f" ] ; then
      if [ "$f" != 'verGo.sh' ] ; then
        if [ "$VERGO_SUM" = `md5sum $f | cut -c1-32` ] ; then
          if [ "$VERBOSE" = 'Y' ] ; then echo "  FILE TO CHECK"; fi
          CHECK_IT='T'
        fi
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

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -n "$UNRESOLVED" ] ; then
  echo "UNRESOLVED VERGO LINKS: $UNRESOLVED"
else
  echo "ALL VERGO LINKS/FILES RESOLVED"
fi

