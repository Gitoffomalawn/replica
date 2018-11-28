# replica

Replica is a script that will make a copy of a directory, and also create an    
archive of that directory for offline storage. Currently, only .tar.gz formats  
are supported.     

Usage: ./replica [OPTIONS]     
Options:     
  -a [IP ADDRESS]   Proxy IP address. If you are using a proxy to login remotely
                    to your machine, use this option input the IP address of the
                    proxy for the purpose of SCP.     
  -b [NUM]          Amount of backup versions to keep. The default is 3.     
 -d [DIRECTORY]     Destination backup directory. This is where your directory
                    will be copied to. The default is ~/TEST.     
 -p [PORT]          Proxy port number. If you are using a proxy to login remotely
                    to your machine, use this option input the port used on the
                    proxy for the purpose of SCP.     
 -s [DIRECTORY]     Source backup directory. This is the directory you wish to
                    back up. The default is ~/TEMP.     
 -t [DIRECTORY]     Path to archive. This is the location for the creation of the
                    .tar.gz archive. The default location is ~/.     

 -A                 Disable the creation of a .tar.gz archive.     
 -B                 Enable unlimited backup versions.
