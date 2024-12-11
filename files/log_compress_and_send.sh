#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
  # Display Help
  echo "Send files and compressed folders to a filedrop url."
  echo
  echo "Syntax: log_compress_and_send [--nofolders, -h, -p password, -e \"gz np\"] -u url -d /var/log/processit"
  echo "OPTIONS"
  echo " -d directory, --directory=diectory"
  echo "      specifies the working directory"
  echo " -u url, --url=url"
  echo "      filedrop url to which cloudsend should upload the files"
  echo " -p password, --password=password"
  echo "      password of the filedrop url"
  echo " -e extension list, --extension=extension list"
  echo "      list of file extensions which should be uploaded. default: gz npy"
  echo "      example --extension=\"gz npy\""
  echo " --nofolders"
  echo "      do not compress folders and send them as a tarball"
  echo " --ignorefolder"
  echo "      ignore folder"
  echo " -h   Print this Help."
  # echo " -v   Verbose mode."
  # echo " -V   Print software version and exit."
echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
DIR_ROTATE_DAYS=0
TARBALL_DELETION_DAYS=60
TARBALL_DELETION_DAYS_SEND=7

SEND_FOLDER=".send"
COMPRESSED_FOLDERS=".compressed_folders"

LOG_DIR=

CLOUDSEND_URL=
CLOUDSEND_PASSWORD=

VERBOSE=false

EXTENSION_LIST="gz npy"

NOFOLDERS=false
IGNOREFODER=

############################################################
# Process the input options.                               #
############################################################
# Get the options
while getopts ":hvd:u:p:e:-:" option; do
    # support long options: https://stackoverflow.com/a/28466267/519360
    if [ "$option" = "-" ]; then   # long option: reformulate OPT and OPTARG
      option="${OPTARG%%=*}"       # extract long option name
      OPTARG="${OPTARG#$option}"   # extract long option argument (may be empty)
      OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi

    case $option in
      h) # display Help
         Help
         exit;;
      v | verbose) # verbose mode
        VERBOSE;;
      d | directory) # directory
        LOG_DIR=$OPTARG;;
      u | url) # filedrop url
        CLOUDSEND_URL=$OPTARG;;
      p | password) # filedrop password
        CLOUDSEND_PASSWORD=$OPTARG;;
      e | extension) # file extension
        EXTENSION_LIST=$OPTARG;;
      nofolders) # no folder
        NOFOLDERS=true;;
      ignorefolder) # ignore folder
        IGNOREFODER=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
    esac
done


if [ -n "$LOG_DIR" ]; then
  if [ -n "$VERBOSE" ]; then
    echo "directory: $LOG_DIR"
  fi
else
  echo "log dir was not set"
  Help
  exit
fi

if [ -n "$CLOUDSEND_URL" ]; then
  if [ -n "$VERBOSE" ]; then
    echo "filedrop url: $CLOUDSEND_URL"
  fi
else
  echo "filedrop url was not set"
  Help
  exit
fi

############################################################
# Function definitions                                     #
############################################################
compress_folder () {
  WDIR=$1
  MIN_DAYS=$2
  COMPRESSED_FOLDERS=$3

  cd $WDIR
  mkdir -p "$COMPRESSED_FOLDERS"

  echo "compressing $WDIR dirs that are $MIN_DAYS days old...";

  for DIR in $(find ./ -maxdepth 1 -mindepth 1 -type d -mtime +"$((MIN_DAYS - 1))" -not -name ".*" -not -name "$IGNOREFODER" | sort); do
    echo -n "compressing $DIR ... ";
    if tar czf "$DIR.tar.gz" "$DIR"; then
      echo "move $DIR.tar.gz into $COMPRESSED_FOLDERS folder"
      mv "$DIR.tar.gz" "$COMPRESSED_FOLDERS"
      echo "done" && rm -rf "$DIR";
    else
      echo "failed";
    fi
  done

  # cd -
}


upload_files () {
  WDIR=$1
  FILENAME=$2
  SEND_FOLDER_NAME=$3

  cd $WDIR

  mkdir -p $SEND_FOLDER_NAME

  echo "uploading $WDIR $FILENAME files "

  for FILE in $(find ./ -maxdepth 1 -type f -name "$FILENAME"); do
      echo "upload $FILE ... "
      if [ -n CLOUDSEND_PASSWORD ]; then
        cloudsend --password "$CLOUDSEND_PASSWORD" "./$FILE" "$CLOUDSEND_URL"
        RV=$?
      else
        cloudsend "./$FILE" "$CLOUDSEND_URL"
        RV=$?
      fi

      if [ $RV -eq 0 ]; then
          mv "./$FILE" "./$SEND_FOLDER_NAME"
      else
          echo "upload failed: rv = $RV"
      fi
  done
  # cd -
}

remove_file () {
  WDIR=$1
  FILENAME=$2
  MIN_DAYS=$3
  
  cd $WDIR

  echo "removing $WDIR $FILENAME files that are $MIN_DAYS days old..."

  for FILE in $(find ./ -maxdepth 1 -type f -mtime +"$((MIN_DAYS - 1))" -name "FILENAME" | sort); do
    echo -n "removing $WDIR/$FILE ... ";
    if rm -f "$WDIR/$FILE"; then
      echo "done";
    else
      echo "failed";
    fi
  done

  # cd -
}

if [ $NOFOLDERS = false ]; then
  compress_folder $LOG_DIR $DIR_ROTATE_DAYS $COMPRESSED_FOLDERS
  upload_files "$LOG_DIR/$COMPRESSED_FOLDERS" "*.gz" $SEND_FOLDER
  remove_file "$LOG_DIR/$COMPRESSED_FOLDERS" "*.gz" $TARBALL_DELETION_DAYS
  remove_file "$LOG_DIR/$COMPRESSED_FOLDERS/$SEND_FOLDER" "*.gz" $TARBALL_DELETION_DAYS_SEND
fi

echo "extension list: $EXTENSION_LIST"

#Field_Separator=$IFS
# set comma as internal field separator for the string list
#IFS=,
for val in $EXTENSION_LIST; do
  upload_files $LOG_DIR "*.$val" $SEND_FOLDER
  remove_file "$LOG_DIR" "*.$val" $TARBALL_DELETION_DAYS
  remove_file "$LOG_DIR/$SEND_FOLDER" "*.$val" $TARBALL_DELETION_DAYS_SEND
done
#IFS=$Field_Separator
