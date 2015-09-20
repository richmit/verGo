#!/bin/bash
# -*- Mode:Shell-script; Coding:utf-8; fill-column:132 -*-

####################################################################################################################################
# @file      verGo.sh
# @author    Mitch Richling <http://www.mitchr.me>
# @Copyright Copyright 2013 by Mitch Richling.  All rights reserved.
# @brief     Find and run applications.@EOL
# @Keywords  
# @Std       bash
#
#            Provides a way to find preferred versions of various applications.  Three modes of operation are provided:
#               1) Run verGo.sh with the -app argument to specify the application name.
#               2) Create a link to verGo.sh.  The name of the link will be used as the "application" name
#               3) Use it on a SHBANG line like so: #!/bin/bash /home/richmit/bin/ruby
#                     * On BSD: #!/bin/bash /home/richmit/bin/ruby
#                     * On Linux: #!/home/richmit/bin/verGo.sh ruby
#                  The first non-recognized argument on the command line will be used as the "application" name.
#
#            Configuration is provided via the ~/.verGoRC file.  The file format is simple.  It is line oriented.  The fist word on
#            the line is the "application", this is optionally followed by a !, and the following items are places to find that
#            application.  The "!" means the application can be wrapped with rlwrap.  They can be other "applications" listed in the
#            config file, or fully qualified path names .
#            
#            The rlwrap thing doesn't work for indirect calls -- i.e. if the config file has references to other app lines.  I'll
#            fix this someday.
#

##----------------------------------------------------------------------------------------------------------------------------------

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
