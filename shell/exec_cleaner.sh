#!/bin/bash
#simple script to delete previously untarred folders
for folder in 201* ; do 

if [ -d "$folder" ] ; then
  echo "Entering $folder"
  cd $folder
  for tarball in *.tar.bz2 ; do
    folder_name="${tarball:0:(-8)}"
    #echo "Found $tarball Folder $folder_name"
    if [ -d "$folder_name" ] ; then
      echo "Deleting $folder_name"
      rm -rf $folder_name
    fi
  done 
  cd ..
fi

done
