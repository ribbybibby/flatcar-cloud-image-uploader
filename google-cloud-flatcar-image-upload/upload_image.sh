#!/bin/bash
set -o errexit
set -o pipefail

# Default values
FLATCAR_LINUX_CHANNEL=stable
FLATCAR_LINUX_VERSION=current
ZONE=europe-west3
FORCE_RECREATE=false
FORCE_REUPLOAD=false

usage() {
	cat <<HELP_USAGE
Usage: $0 [OPTION...]

 Required arguments:
  -b, --bucket-name Name of GCP bucket for storing images.
  -p, --project-id  ID of the project for creating bucket.

 Optional arguments:
  -c, --channel     Flatcar Linux release channel. Defaults to '${FLATCAR_LINUX_CHANNEL}'.
  -v, --version     Flatcar Linux version. Defaults to '${FLATCAR_LINUX_VERSION}'.
  -i, --image-name  Image name, which will be used later in Lokomotive configuration. Defaults to 'flatcar-<channel>'.

 Optional flags:
   -f, --force-reupload If used, image will be uploaded even if it already exist in the bucket.
   -F, --force-recreate If user, if compute image already exist, it will be removed and recreated.
HELP_USAGE
}

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	-h|--help)
		usage
		exit 0
	;;
	-c|--channel)
		FLATCAR_LINUX_CHANNEL="$2"
		shift
		shift
	;;
	-v|--version)
		FLATCAR_LINUX_VERSION="$2"
		shift
		shift
	;;
	-i|--image-name)
		IMAGE_NAME="$2"
		shift
		shift
	;;
	-b|--bucket-name)
		BUCKET_NAME="$2"
		shift
		shift
	;;
	-p|--project-id)
		PROJECT_ID="$2"
		shift
		shift
	;;
	-z|--zone)
		ZONE="$2"
		shift
		shift
	;;
	-f|--force-reupload)
		FORCE_REUPLOAD=true
		shift
	;;
	-F|--force-recreate)
		FORCE_RECREATE=true
		shift
	;;
	*)
		echo "Unknown parameter $1"
		echo
		usage
		exit 1
	;;
esac
done

IMAGE_NAME="${IMAGE_NAME:-flatcar-${FLATCAR_LINUX_CHANNEL}}"

if [[ -z "${BUCKET_NAME}" ]]; then
	echo "--bucket-name must be specified."
	echo
	usage
	exit 1
fi

if [[ -z "${PROJECT_ID}" ]]; then
	echo "--project-id must be specified."
	echo
	usage
	exit 1
fi

echo "Logging in into Google Cloud."
gcloud auth login

echo
echo "Setting default project to '$PROJECT_ID'"
gcloud config set project $PROJECT_ID

BUCKET_PATH=gs://$BUCKET_NAME
echo
echo "Checking if GCP bucket '$BUCKET_NAME' exists"

echo
if gsutil ls $BUCKET_PATH 2>&1 >/dev/null; then
  echo "Bucket exists, skipping creation step."
else
  echo "Bucket does not exist, creating..."
  gsutil mb -l $ZONE $BUCKET_PATH
fi

IMAGE_FILENAME="flatcar_production_gce.tar.gz"
IMAGE_URL="https://${FLATCAR_LINUX_CHANNEL}.release.flatcar-linux.net/amd64-usr/${FLATCAR_LINUX_VERSION}/${IMAGE_FILENAME}"

echo
echo "Downloading Flatcar Linux image from $IMAGE_URL..."
wget $IMAGE_URL

BUCKET_IMAGE_PATH=$BUCKET_PATH/$IMAGE_FILENAME
echo
if [[ "$FORCE_REUPLOAD" = true ]]; then
	echo "Uploading an image to the bucket."
	gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp $IMAGE_FILENAME $BUCKET_IMAGE_PATH
else
	echo "Uploading an image to the bucket (if image already exist, it won't be uploaded twice. If you want to force reupload, run with --force-reupload."
	gsutil -o GSUtil:parallel_composite_upload_threshold=150M cp -n $IMAGE_FILENAME $BUCKET_IMAGE_PATH
fi

CREATE_IMAGE=true
if gcloud compute images describe $IMAGE_NAME 2>&1 >/dev/null; then
	echo
	if [[ "$FORCE_RECREATE" = true ]]; then
		echo "Removing compute image '$IMAGE_NAME'."
                gcloud compute images delete $IMAGE_NAME
	else
		echo "Image exists. If you want to recreate it, run with --force-recreate."
		CREATE_IMAGE=false
	fi
fi

echo
if [[ "$CREATE_IMAGE" = true ]]; then
	echo "Creating compute image from uploaded image."
	gcloud compute images create $IMAGE_NAME \
		--source-uri $BUCKET_IMAGE_PATH \
		--family flarcar-linux
fi
