#!/bin/bash



echo "Inside build_and_push.sh file"
SDLC_ENVIRONMENT=$1
DOCKER_IMAGE_NAME=$2

echo "value of DOCKER_IMAGE_NAME is $DOCKER_IMAGE_NAME"

if [ "$DOCKER_IMAGE_NAME" == "" ]
then
    echo "Usage: $0 <image-name>"
    exit 1
fi
src_dir=$CODEBUILD_SRC_DIR

# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi


region=$AWS_REGION
echo "Region value is : $region"

ecr_repo_name=$DOCKER_IMAGE_NAME"-ecr-repo"
echo "value of ecr_repo_name is $ecr_repo_name"


aws ecr describe-repositories --repository-names ${ecr_repo_name} || aws ecr create-repository --repository-name ${ecr_repo_name}



image_name=$SDLC_ENVIRONMENT-$DOCKER_IMAGE_NAME-$CODEBUILD_BUILD_NUMBER


aws ecr get-login-password | docker login --username AWS --password-stdin ${account}.dkr.ecr.${region}.amazonaws.com

fullname="${account}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_name}:$image_name"
echo "fullname is $fullname"
# Build the docker image locally with the image name and then push it to ECR with the full name.

docker build -t ${image_name} $CODEBUILD_SRC_DIR/docker_python/
echo "Docker build after"

echo "image_name is $image_name"
docker tag ${image_name} ${fullname}
docker images
docker push ${fullname}
if [ $? -ne 0 ]
then
    echo "Docker Push Event did not Succeed with Image ${fullname}"
    exit 1
else
    echo "Docker Push Event is Successful with Image ${fullname}"
fi
