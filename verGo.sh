#!/bin/bash
# -*- Mode:Shell-script; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      verGo.sh
# @author    Mitch Richling <https://www.mitchr.me>
# @brief     Find and run applications.@EOL
# @std       bash_3
# @copyright 
#  @parblock
#  Copyright (c) 1993,1996,1997,2005,2011,2016, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
#     specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  @endparblock
# @filedetails
#
#  Provides a way to find preferred versions of various applications.  
#     1) Create a link to verGo.sh.  The name of the link will be used as the "application" name
#        This allows us to create a personal "bin" directory containing links to verGo.sh specifying various applications we use.
#     2) Run verGo.sh with the -app argument to specify the application name.
#     3) Run verGo.sh with the application name after any verGo.sh options. On Linux, this mode can be used for SHBANG lines:
#           #!/home/richmit/bin/verGo.sh ruby
#     4) On some platforms (BSDs for example) SHBANG lines require a binary, so you can use verGo.sh this way:
#           #!/bin/bash /home/richmit/bin/ruby
#
#  Command line options:
#    -noRun ................... Don't actually run the application
#    -app APP_NAME ............ Name of the application to run
#    -noWrap .................. Enable or disable rlwrap & winpty
#    -prtCmd .................. Print the command we find
#    -prtVar .................. Print the variables for the command we find
#                               Each variable is printed on a separate line
#                               If -prtCmd & -prtVar are both provided, the command is printed first
#    -prtFmt <UNIX|WIN|DOS> ... Print format for -prtCmd
#    -noErrors ................ Don't print errors -- still, exit, just don't print anything
#    -rcfile <FILE> ........... Use this RC file instead of ~/.verGoRC
#    -debug ................... Enable debugging
#
#  Exit Codes
#    - 7 ERROR: Invalid value for -prtFmt
#    - 6 ERROR: No application name provided!
#    - 5 ERROR: rcfile not found!
#    - 4 ERROR: Duplicate app found in rcfile
#    - 3 ERROR: Application not supported
#    - 2 ERROR: Application supported, but no executable found
#    - 1 ERROR: Application supported, executable found, failed to exec
#    - 0 Application found in -noRun mode
#
#  Recipes:
#    - To just see if verGo.sh knows about an application: Use the -app and -noRun options.
#    - To just print the command binary that would be executed: Use the -app, -noRun, and -prtCmd options.
#
#  Configuration file
#    The default configuration file is ~/.verGoRC.  This may be overridden via the -rcfile option.  
#    A simple line oriented format is used with each line looking like:
#        [BOOLEAN_EXPR ::: ] APP_NAME [-r HIST_NAME|-w] [VARIABLES] === ALTERNATIVES
#    Syntax rules:
#      - The APP_NAME is the name of the application and may not contain whitespace
#      - When present, the HIST_NAME, must not contain whitespace
#      - VARIABLES is a space separated list of variable definitions of the form FOO=BAR -- may be single quoted
#        - Example: PATH=/usr/bin 'HOMER_RANGE=/a/path with/spaces in it/'
#      - ALTERNATIVES is a space separated list of fully qualified paths or APP_NAMEs -- may be single quoted
#        - Example: /a/path '/path/with spaces/foo.exe' anAppName /another/path
#      - Note the whitespace in front of and after both operators (":::" and "===")!
#      - BOOLEAN_EXPR is a shell boolean expression -- something that can be placed between square brackets
#        - Variables available for use in this expression include:
#          - HOSTNAME ........... Hostname
#          - OSTYPE ............. OS family name (msys for MSYS2, 
#          - MACHTYPE ........... Bash built-in for machine hardware type
#          - HOME ............... Usually set to the user home directory (some systems don't set this)
#          - PATH ............... The system path
#          - MJR_LOC ............ Location of system as defined by the existence of a file like ~/mjrLOC-NAME
#        - Examples
#          - "$HOSTNAME" == 'hofud'
#          - "$OSTYPE" == 'msys' -a "$MACHTYPE" == 'x86_64'
#
################################################################################################################################################################

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
DEBUG='NO'
if [ -n "$VERGODEBUG" ]; then
   DEBUG='YES'
   if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: Debug enabled via VERGODEBUG environment variable"; fi
fi
DBGPRS='NO'
PRTFMT='UNIX'
APPNAME=''
DOERRORS='YES'
RUNMODE='YES'
PRTCMD='NO'
PRTVAR='NO'
RCFILE=~/.verGoRC
DOWRAP='YES'
while [ -z "$HAVEMORE" ] ; do
  case "$1" in
    -noRun    ) RUNMODE='NO'; DOERRORS='NO'; shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noRun"           ; fi ;;
    -app      ) APPNAME=$2;                  shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -app $APPNAME"    ; fi ;;
    -noWrap   ) DOWRAP='NO';                 shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noWrap"          ; fi ;;
    -prtCmd   ) PRTCMD='YES';                shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -prtCmd"          ; fi ;;
    -prtVar   ) PRTVAR='YES';                shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -prtVar"          ; fi ;;
    -prtFmt   ) PRTFMT=$2;                   shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -prtFmt $PRTFMT"  ; fi ;;
    -noErrors ) DOERRORS='NO';               shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noErrors"        ; fi ;;
    -rcfile   ) RCFILE=$2;                   shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -rcfile $RCFILE"  ; fi ;;
    -debug    ) DEBUG='YES';                 shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -debug"           ; fi ;;
    *         ) HAVEMORE='NOPE';                                                                                                            ;;
  esac
done

if [ -z "$APPNAME" ] ; then
  APPNAME=`/usr/bin/basename $0`
else
  if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: Application name provided on command line" ; fi
fi

if [ "$APPNAME" = 'verGo.sh' ] ; then
  APPNAME="$1"
  shift
  if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: Running in SHBANG mode!"; fi
fi

if [ "$DOWRAP" == 'YES' -a "$TERM" == 'dumb' ]; then # winpty & rlwrap won't work in a dumb terminal
  if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Wrap disabled because of dumb terminal!" ; fi
  DOWRAP='NO'
fi

if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: APPNAME  = $APPNAME "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: DOERRORS = $DOERRORS"; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: RUNMODE  = $RUNMODE "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: DEBUG    = $DEBUG   "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: PRTCMD   = $PRTCMD  "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: PRTVAR   = $PRTVAR  "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: PRTFMT   = $PRTFMT  "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: RCFILE   = $RCFILE  "; fi
if [ "$DEBUG" = 'YES' ] ; then echo "DEBUG: DOWRAP   = $DOWRAP  "; fi

if [ "$PRTFMT" != 'UNIX' -a "$PRTFMT" != 'WIN' -a "$PRTFMT" != 'DOS' ]; then
  if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Invalid value for -prtFmt: $PRTFMT"; fi
  exit 7
fi

if [ -z "$APPNAME" ]; then
  if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: No application name provided!"; fi
  exit 6
fi

if [ ! -e "$RCFILE" ] ; then
  if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: $RCFILE not found!"; fi
  exit 5
fi

MJR_LOC='UNKNOWN'
if [ -e ~/.mjrLOC-*[A-Z] ]; then
  MJR_LOC=$(echo ~/.mjrLOC-*[A-Z])
  MJR_LOC=${MJR_LOC#*LOC-}
fi

# MJR_DNSDOMAIN='QUERY'
# function lookupDNSDOMAIN {  
#   if [ "$MJR_DNSDOMAIN" == 'QUERY' ]; then
#     if [ -e /usr/bin/dnsdomainname ]; then
#       MJR_DNSDOMAIN=$(/usr/bin/dnsdomainname)
#     else
#       MJR_DNSDOMAIN='UNKNOWN'
#     fi
#   fi
# }

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Read in config file.  
declare -a verGoRCwino
declare -a verGoRCrlwo
declare -a verGoRCapps
declare -a verGoRCvars
declare -a verGoRClist
while IFS= read -r line; do
  if [ -n "$line" ]; then
    if [[ "$line" != '#'* ]]; then
      if [[ "$line" == *' === '* ]]; then
        if [ "$DBGPRS" = 'YES' ] ; then echo "LINE: $line"; fi
        tstbit='-n TRUE'
        if [[ "$line" == *' ::: '* ]]; then
          tstbit=${line%% ::: *}
        fi
        if [ "$DBGPRS" = 'YES' ] ; then echo "   tstbit: $tstbit"; fi
        if eval '[' $tstbit ']' ; then
          lstbit=${line#* ::: } # Not final value -- app options list
          varbit=${lstbit%% === *} # Not final value -- options
          appbit=${varbit%% *}
          if [ "$DBGPRS" = 'YES' ] ; then echo "   appbit: $appbit"; fi
          lstbit=${lstbit#* === }
          if [ "$DBGPRS" = 'YES' ] ; then echo "   lstbit: $lstbit"; fi
          if [[ "$varbit" == *' '* ]]; then
            varbit=${varbit#* }
          else
            varbit=''
          fi
          for oapp in ${verGoRCapps[@]}; do
            if [ "$oapp" == "$appbit" ]; then
              if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Duplicate app in $RCFILE: $appbit"; fi
              exit 4
            fi
          done 
          winbit='NO'
          if [[ "$varbit" == '-w'* ]]; then
            winbit='YES'
            varbit=${varbit#-w}
            varbit=${varbit# }
          fi
          if [ "$DBGPRS" = 'YES' ] ; then echo "   winbit: $winbit"; fi
          rlwbit=''
          if [[ "$varbit" == '-r'* ]]; then
            varbit=${varbit#-r }
            rlwbit=${varbit%% *}
            varbit=${varbit#* }
          fi
          if [ "$DBGPRS" = 'YES' ] ; then echo "   rlwbit: $rlwbit"; fi
          if [ "$DBGPRS" = 'YES' ] ; then echo "   varbit: $varbit"; fi
          verGoRCrlwo+=("$rlwbit")
          verGoRCwino+=("$winbit")
          verGoRCapps+=("$appbit")
          verGoRCvars+=("$varbit")
          verGoRClist+=("$lstbit")
        else
          if [ "$DBGPRS" = 'YES' ] ; then echo "   ABORTED"; fi
        fi
      fi
    fi
  fi
done < "$RCFILE"

# for verGoRCIdx in "${!verGoRCapps[@]}"; do
#   echo "IDX: $verGoRCIdx "
#   echo "     app: =>${verGoRCapps[$verGoRCIdx]}<="
#   echo "     win: =>${verGoRCwino[$verGoRCIdx]}<="
#   echo "     rwl: =>${verGoRCrlwo[$verGoRCIdx]}<="
#   echo "     var: =>${verGoRCvars[$verGoRCIdx]}<="
#   echo "     alt: =>${verGoRClist[$verGoRCIdx]}<="
# done

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
function findAppIdx {
  IFS=
  for faii in "${!verGoRCapps[@]}"; do
    if [ "$1" == ${verGoRCapps[faii]} ]; then
      echo $faii
      return 0
    fi
  done
  echo ''
  return 1
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
function findAppBin {
  IFS=
  for fabi in "${!verGoRCapps[@]}"; do
    if [ "$1" == ${verGoRCapps[fabi]} ]; then
      IFS=$'\n'
      for fabbp in `echo ${verGoRClist[fabi]} | /usr/bin/xargs -n 1 /bin/echo`; do # Krazy thing we do to support quoted paths
        local fabcbp="$fabbp"
        if [ ${fabbp:0:1} != '/' ] ; then
          fabcbp=$(findAppBin "$fabbp")
          if [ -n "$fabcbp" ]; then
            echo "$fabcbp"
            return 0
          fi
        else
          if [ -e "$fabcbp" ] ; then
            echo "$fabi $fabcbp"
            return 0
          fi
        fi
      done
    fi
  done
  echo ''
  return 1
}

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
if [ -z "$(findAppIdx "$APPNAME")" ]; then
  if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application not supported: $APPNAME"; fi
  exit 3
else
  SRES=$(findAppBin "$APPNAME")
  if [ -z "$SRES" ]; then
    if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application supported, but no executable found: $APPNAME"; fi
    exit 2
  else
    verGoIdx=${SRES%% *}
    verGoBin=${SRES#* }
    if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Application found:      $verGoBin" ; fi
    if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Application final app:  ${verGoRCapps[$verGoIdx]}" ; fi
    if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Application variables:  ${verGoRCvars[$verGoIdx]}" ; fi
    if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Application rlwrap opt: '${verGoRCrlwo[$verGoIdx]}'" ; fi
    if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Application winpty opt: ${verGoRCwino[$verGoIdx]}" ; fi
    if [ "$PRTCMD"  = 'YES' ] ; then 
      if   [ "$PRTFMT" == 'UNIX' ]; then
        echo "$verGoBin"
      elif [ "$PRTFMT" == 'WIN'  ]; then
        cygpath -w "$verGoBin"
      elif [ "$PRTFMT" == 'DOS'  ]; then
        cygpath -d "$verGoBin"
      fi
    fi
    # Create an array with variables -- so we can quote them later for env.  Also print vars if requested.
    declare -a verGoVars
    verGoVars+=("VERGO=$APPNAME")
    IFS=$'\n'
    for varset in `echo ${verGoRCvars[$verGoIdx]} | /usr/bin/xargs -n 1 /bin/echo`; do 
      verGoVars+=("$varset")
      if [ "$PRTVAR" == 'YES' ] ; then 
        echo "$varset"
      fi
    done
    if [ "$RUNMODE" = 'YES' ] ; then
      IFS=
      WINBIN='winpty'
      RLWBIN='rlwrap'
      if [ "$DOWRAP" == 'YES' -a "${verGoRCwino[$verGoIdx]}" == 'YES' ]; then
        SRES=$(findAppBin "winpty")
        if [ -n "$SRES" ]; then
          WINBIN=${SRES#* }
        else
          if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Could not find winpty in RCFILE" ; fi
        fi
      else
        if [ "$DOWRAP" == 'YES' -a -n "${verGoRCrlwo[$verGoIdx]}" ]; then
          SRES=$(findAppBin "rlwrap")
          if [ -n "$SRES" ]; then
            RLWBIN=${SRES#* }
          else
            if [ "$DEBUG"   = 'YES' ] ; then echo "DEBUG: Could not find rlwrap in RCFILE" ; fi
          fi
        fi
      fi
      # We have everything we need.  Run it...
      if [ "$DOWRAP" == 'YES' -a "${verGoRCwino[$verGoIdx]}" == 'YES' ]; then
        exec env "${verGoVars[@]}" "$WINBIN" "$verGoBin" "$@"
      else
        if [ "$DOWRAP" == 'YES' -a -n "${verGoRCrlwo[$verGoIdx]}" ]; then
          exec env "${verGoVars[@]}" "$RLWBIN" -C "${verGoRCrlwo[$verGoIdx]}" "$verGoBin" "$@"
        else
          exec env "${verGoVars[@]}" "$verGoBin" "$@"
        fi
      fi
      if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application supported, executable found, failed to exec: $APPNAME"; fi
      exit 1
    fi
    exit 0
  fi
fi


