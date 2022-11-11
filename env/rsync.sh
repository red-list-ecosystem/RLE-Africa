# The Data folder is not tracked by git, because it contains large files and not all data is open access
# we can use rsync to synchronize the data already available in another folder or computer
# send data from a local folder to a remote folder
rsync -gloptrunv $SCRIPTDIR/Data/ ${USER}@${REMOTEHOST}:~/proyectos/IUCN-RLE/$PROJECTNAME/Data
# receive data from a remote folder to the local copy of the repository
rsync -gloptrunv ${USER}@${REMOTEHOST}:~/proyectos/IUCN-RLE/$PROJECTNAME/Data $SCRIPTDIR/Data/
