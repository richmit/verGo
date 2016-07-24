#!/bin/bash
# -*- Mode:Shell-script; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      verGo.sh
# @author    Mitch Richling <https://www.mitchr.me>
# @brief     Find and run applications.@EOL
# @std       bash
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
#  Provides a way to find preferred versions of various applications.  Three modes of operation are provided:
#     1) Run verGo.sh with the -app argument to specify the application name.
#     2) Create a link to verGo.sh.  The name of the link will be used as the "application" name
#     3) Use it on a SHBANG line like so (works on BSDs and Linux): 
#           #!/bin/bash /home/richmit/bin/ruby
#        On Linux you can use the above, or simplify it to:
#           #!/home/richmit/bin/verGo.sh ruby
#        The first non-recognized argument on the command line will be used as the "application" name.
#
#  Configuration is provided via the ~/.verGoRC file.  The file format is simple.  It is line oriented.  The fist word on the line is the "application", this
#  is optionally followed by a !, and the following items are places to find that application.  The "!"  means the application can be wrapped with rlwrap.
#  They can be other "applications" listed in the config file, or fully qualified path names .
#  
#  The rlwrap thing doesn't work for indirect calls -- i.e. if the config file has references to other app lines.  I'll fix this someday.
#
################################################################################################################################################################

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
APPNAME=''
DOERRORS=YES
RUNMODE=YES
DEBUG=NO
PRTCMD=NO
if [ -t 1 ] ;
then
    APPINT=YES
else
    APPINT=NO
fi
while [ -z "$HAVEMORE" ] ; do
    case "$1" in
        -noRun       ) RUNMODE=NO; DOERRORS=NO;      shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noRun"        ; fi ;;
        -app         ) APPNAME=$2;                   shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -app $APPNAME" ; fi ;;
        -rlwrap      ) APPINT=$2;                    shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -i $APPINT"    ; fi ;;
        -prtCmd      ) PRTCMD=YES;                   shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -prtCmd"       ; fi ;;
        -noErrors    ) DOERRORS=NO;                  shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noErrors"     ; fi ;;
        -debug       ) DEBUG=YES;                    shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -debug"        ; fi ;;
        *            ) HAVEMORE='NOPE';                                                                                                              ;;
    esac
done

if [ -z "$APPNAME" ] ; then
    APPN=`basename $0`
else
    if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application name provided on command line" ; fi
    APPN="$APPNAME"
fi

if [ "$APPN" = 'verGo.sh' ] ; then
    APPN="$1"
    shift
    if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Running in SHBANG mode!"; fi
fi

APPI=`grep "^$APPN " ~/.verGoRC`

if echo $APPI | egrep "^$APPN i(-| )" 2>/dev/null 1>/dev/null ; then
    if echo $APPI | egrep "^$APPN i " 2>/dev/null 1>/dev/null ; then
        if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap: YES!"; fi
        APPP=`echo $APPI | sed "s/^$APPN i //"`
        RLWM='YES'
        RLWP=`verGo.sh -prtCmd -noRun rlwrap`
        RLWC="$APPN"
    else
        if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap: YES with command name!"; fi
        APPP=`echo $APPI | sed "s/^$APPN i-[a-zA-Z]* //"`
        RLWM='YES'
        RLWP=`verGo.sh -prtCmd -noRun rlwrap`
        RLWC=`echo $APPI | sed "s/^$APPN i-//" | sed 's/ .*$//'`
    fi    
else
    if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap: NO!"; fi
    APPP=`echo $APPI | sed "s/^$APPN //"`
    RLWM='NO'
    RLWP=''
    RLWA=''
    RLWC=''
fi

DORL=NO
if [ -n "$RLWP" ] ; then
    if [ "$APPINT" = "YES" ] ; then
        if [ "$RLWM" = "YES" ] ; then
            DORL=YES
        fi
    fi
fi

if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application name:       $APPN"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application info:       $APPN"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application paths:      $APPP"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application rlwrapable: $RLWM"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap requested:       $APPINT" ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap path:            $RLWP"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: rlwrap command name:    $RLWC"   ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Use rlwrap:             $DORL"   ; fi

if [ -z "$APPP" ] ; then
    if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application not supported: $APPN"; fi
    exit
else
    for BINPOS in $APPP; do
        if [ ${BINPOS:0:1} != '/' ] ; then
            CBINPOS=`/home/richmit/bin/verGo.sh -app $BINPOS -noRun -prtCmd`
        else
            CBINPOS="$BINPOS"
        fi
        if [ -x "$CBINPOS" ] ; then
            if [ "$DEBUG"   = 'YES' ] ; then echo "INFO: Application found: $CBINPOS" ; fi
            if [ "$PRTCMD"  = 'YES' ] ; then echo "$CBINPOS" ; fi
            if [ "$RUNMODE" = 'YES' ] ; then
                if [ "$DORL" = "YES" ] ; then
                    exec "$RLWP" -C "$RLWC" "$CBINPOS" "$@"
                else
                    exec "$CBINPOS" "$@"
                fi
            fi
            exit
        fi
    done
    if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application not found: $APPN"; fi
    exit
fi
