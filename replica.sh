#!/bin/bash

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                      _  _                                             #
#                     | |(_)                Replica, a backup script    #
#    _ __  ___  _ __  | | _   ___  __ _     ------------------------    #
#   | '__|/ _ \| '_ \ | || | / __|/ _` |    Author: Techn0Viking        #
#   | |  |  __/| |_) || || || (__| (_| |    Version: 1.0                #
#   |_|   \___|| .__/ |_||_| \___|\__,_|    License: LGPL-3.0           #
#              | |                                                      #
#              |_|                                                      #
#                                                                       #
#               https://github.com/Gitoffomalawn/replica                #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Variables (defaults)
src=~/TEMP                                     # Source directory (-s)
dest=~/TEST                                    # Destination directory (-d)
dir=`date +%Y%m%d`                             # Sub directory naming scheme
b=3                                            # Backup versions to keep (-b)
targz=~/$dir.tar.gz                            # Path to archive for offline backup (-t)
ip=`echo $SSH_CONNECTION | awk '{print $3}'`   # Machine IP address (for scp) (-a)
port=`echo $SSH_CONNECTION | awk '{print $4}'` # Port used for SSH (for scp) (-p)
p=~/                                           # Path relativity (for scp)
B=0                                            # Switch for unlimited backups (-B)
A=0                                            # Switch for disabling archiving (-A)
#method=scp                                    # Archive download method (-m)

# Functions
## Overwrite all files in target directory
function overwrite {
    echo -e "\n\nOverwriting files in local backup directory: $dest/$dir"
    rm -rf $dest/$dir
    mkdir $dest/$dir
    cp -r . $dest/$dir
}

## Update older files in destination with newer from source
function update {
    echo -e "\n\nUpdating files in local backup directory: $dest/$dir"
    cp -r -v -u  . $dest/$dir
}

## Abort the script operation (execute no further commands)
function abort_normal {
    echo -e "\nBackup script aborted.\n"
    cd - > /dev/null
    exit 0
}

function abort_abnormal {
    exit 1
}

## Validate whether and IP is in valid format
function validFormatIP {
    echo $ip | grep -w -E -o '^(25[0-4]|2[0-4][0-9]|1[0-9][0-9]|[1]?[1-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' > /dev/null
    if [ $? -eq 0 ]
    then
        return 0
    else
        echo -e "\n[Err: Invalid IP address]\n"
        abort_abnormal
    fi
}

## Validate port number range
function validNetPort {
    if [ $port -ge 0 -a $port -le 65535 ]
    then
        return 0
    else
        echo -e "\n[Err: Invalid network port number]\n"
        abort_abnormal
    fi
}

## Validate whole numbers
function wholeNum {
    re_isanum='^[0-9]+$'
    if ! [[ $b =~ $re_isanum ]] ; then
        echo -e "\n[Err: Number of backups must be a positive, whole number]\n"
        abort_abnormal
    elif [[ $b -eq "0" ]]; then
        echo -e "\n[Err: Number of backups must be larger than 0]\n"
        abort_abnormal
    else
        return 0
    fi
}

## Validate .tar.gz
function archiveTar {
    gz=`echo ${targz:(-7)}`
    if [ $gz == ".tar.gz" ] ; then
        return 0
    else
        echo -e "\n[Err: Supplied archive name must be a .tar.gz file]\n"
        abort_abnormal
    fi
}

## Print help text
function help {
    echo -e "\nReplica is a script that will make a copy of a directory, and also create an\
    \narchive of that directory for offline storage. Currently, only .tar.gz formats\
  \nare supported. \
    \n \
    \nUsage: ./replica [OPTIONS] \
    \nOptions: \
    \n-a [IP ADDRESS]    Proxy IP address. If you are using a proxy to login remotely\n\
                   to your machine, use this option input the IP address of the\n\
                   proxy for the purpose of SCP. \
    \n-b [NUM]           Amount of backup versions to keep. The default is 3. \
    \n-d [DIRECTORY]     Destination backup directory. This is where your directory\n\
                   will be copied to. The default is ~/TEST. \
    \n-p [PORT]          Proxy port number. If you are using a proxy to login remotely\n\
                   to your machine, use this option input the port used on the \n\
                   proxy for the purpose of SCP. \
    \n-s [DIRECTORY]     Source backup directory. This is the directory you wish to\n\
                   back up. The default is ~/TEMP. \
    \n-t [DIRECTORY]     Path to archive. This is the location for the creation of the\n\
                   .tar.gz archive. The default location is ~/. \
    \n \
    \n-A                 Disable the creation of a .tar.gz archive. \
    \n-B                 Enable unlimited backup versions.\n"
    exit 0
}

while getopts ":s:d:b:t:a:p:ABh" options; do
    case "${options}" in
        s)
          src=${OPTARG}
          ;;
        d)
          dest=${OPTARG}
          ;;
        b)
          b=${OPTARG}
          wholeNum
          ;;
        t)
          targz=${OPTARG}
          archiveTar
          ;;
        a)
          ip=${OPTARG}
          validFormatIP
          ;;
        p)
          port=${OPTARG}
          validNetPort
          ;;
        A)
          A=1
          ;;
        B)
          B=1
          ;;
        h)
          help
          ;;
        :)
          echo -e "\n[Err: -${OPTARG} requires an argument]\n"
          abort_abnormal
          ;;
        *)
          echo -e "\n[Err: Invalid option specified]"
          echo -e "\nPlease use -h for an overview of usable options.\n"
          abort_abnormal
          ;;
    esac
done

# Change directory to source directory
cd $src

# Check if target directory already exists, and act accordingly
if [ -d $dest/$dir ]; then
### If the directory exists, ask user what to do
    echo -e "\nThe directory $dest/$dir already exists."
    diff=`diff -r $dest/$dir $src/`   # Source/destination comparison
    err=$?                            # diff exit code extraction
    if [ $err == 0 ]; then
        echo -e "\nNo changes have been detected between $dest/$dir and $src"
        read -r -n 1 -t 60 -p "What would you like to do? [O]verwrite, \
[A]bort: " input
        case $input in
            [oO])
         overwrite
         ;;
            *)
         abort_normal
         ;;
        esac
    elif [ $err == 1 ]; then
        read -r -n 1 -t 60 -p "What would you like to do? [O]verwrite, \
[U]pdate, [A]bort: " input
        case $input in
            [oO])
         overwrite
         ;;
            [uU])
         update
         ;;
            *)
         abort_normal
         ;;
        esac
    else
        echo -e "\n[Err: Failed to execute diff]\n"
        abort_abnormal
    fi
else
### If target directory doesn't exist create it and copy files over
    echo -e "\nCopying files to local backup directory: $dest/$dir"
    mkdir -p $dest/$dir
    cp -r . $dest/$dir
fi

# Create tar archive for offline backup
if [ "$A" == "0" ]; then
    echo -e "\nCreating archive for download: $targz"
    tar -czf $targz -C $dest/$dir .
fi

# Remove the oldest backup directories
match=`echo $dir | cut -c1-4`
d=`ls -l $dest | grep ^d | awk '{print $9}' | grep ^$match | wc -l` # Directory counter
while [ $d -gt $b -a "$B" == "0" ]
do
    echo -e "\nRemoving old backup directory: $dest/\
`ls -ltr $dest | awk '{print $9}' | head -n2 | tail -1`"
    rm -rf $dest/`ls -ltr $dest | awk '{print $9}' | head -n2 | tail -1`
    d=$((d-1))
done

# Download insctructions
if [ "$port" == "22" -o "$port" == "" ]; then # Port checker
    port=""
else
    port="-P $port "
fi

if [ "$A" == "0" ]; then
    echo -e "\n===============================================================\n"
    echo -e "Please download `basename $targz` to another machine for backup.\n\
Use the following command on your local machine:\n\n\
$(tput setaf 2)$(tput setab 0) scp $port`whoami`@$ip:\
`realpath $targz --relative-to=$p` . $(tput sgr 0)"
    echo -e "\n===============================================================\n"
else
    echo -e "\r"
fi

# Return to original pwd
cd - > /dev/null
