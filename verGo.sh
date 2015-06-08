#!/bin/bash
# -*- Mode:Shell-script; Coding:utf-8; fill-column:132 -*-

####################################################################################################################################
# @file      verGo.sh
# @author    Mitch Richling <http://www.mitchr.me>
# @Copyright Copyright 2013 by Mitch Richling.  All rights reserved.
# @Revision  $Revision: 1.4 $ 
# @SCMdate   $Date: 2013/10/27 17:50:45 $
# @brief     Find and run applications.@EOL
# @Keywords  
# @Std       bash
#
#            Provides a way to find preferred versions of various applications.  Three modes of operation are provided:
#               1) Run verGo.sh with the -app argument to specify the application name.
#               2) Create a link to verGo.sh.  The name of the link will be used as the "application" name
#               3) Use it on a SHBANG line like so: #!/home/richmit/bin/verGo.sh ruby
#                  The first non-recognized argument on the command line will be used as the "application" name.
#                  One could also do something like this: #!/home/richmit/bin/verGo.sh -app ruby
#
#            Configuration is provided via the ~/.verGoRC file.  The file format is simple.  It is line oriented.  The fist word on
#            the line is the "application", and the following items are places to find that application.  They can be other
#            "applications" listed in the config file, or fully qualified path names .
#            

##----------------------------------------------------------------------------------------------------------------------------------

APPNAME=''
DOERRORS=YES
RUNMODE=YES
DEBUG=NO
PRTCMD=NO
while [ -z "$HAVEMORE" ] ; do
    case "$1" in
        -noRun    ) RUNMODE=NO; DOERRORS=NO;      shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noRun"    ; fi ;;
        -app      ) APPNAME=$2;                   shift; shift ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -app"      ; fi ;;
        -prtCmd   ) PRTCMD=YES;                   shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -prtCmd"   ; fi ;;
        -noErrors ) DOERRORS=NO;                  shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -noErrors" ; fi ;;
        -debug    ) DEBUG=YES;                    shift        ; if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Command line arg: -debug"    ; fi ;;
        *         ) HAVEMORE='NOPE';                                                                                                          ;;
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
APPP=`echo $APPI | sed "s/^$APPN //"`

if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application name:  $APPN" ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application info:  $APPN" ; fi
if [ "$DEBUG" = 'YES' ] ; then echo "INFO: Application paths: $APPP" ; fi

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
            if [ "$RUNMODE" = 'YES' ] ; then exec "$CBINPOS" "$@"; fi
            if [ "$PRTCMD"  = 'YES' ] ; then echo "$CBINPOS"     ; fi
            exit
        fi
    done
    if [ "$DOERRORS" = 'YES' ] ; then echo "ERROR: Application not found: $APPN"; fi
    exit
fi


