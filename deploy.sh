#!/usr/bin/env bash

source dump-aws-logs.sh

APPDIR=target/
BUNDLEDIR=target/bundle

function bundle() {
    rm -f response.txt

    mvn clean package -DskipTests=true -Dnative=true -Dnative-image.docker-build=quay.io/quarkus/centos-quarkus-native-image:graalvm-1.0.0-rc15

    mkdir -p ${BUNDLEDIR} target
    cp bootstrap ${BUNDLEDIR}/bootstrap
    mv ${APPDIR}/*-runner ${BUNDLEDIR}/runner
    cd ${BUNDLEDIR} && zip -q function.zip runner bootstrap ; cd -
}

bundle

clearStreams

echo Deleting old function
aws lambda delete-function \
    --function-name bash-runtime2

echo Creating function
aws lambda create-function \
    --function-name bash-runtime2 \
    --timeout 10 \
    --zip-file fileb://${BUNDLEDIR}/function.zip \
    --handler runner \
    --runtime provided \
    --role ${LAMBDA_ROLE_ARN}

exit

echo
aws lambda invoke --function-name bash-runtime2 --payload '{"firstName":"James", "lastName": "Lipton"}' response.txt
cat response.txt
echo

echo
aws lambda invoke --function-name bash-runtime2 --payload '{"firstName":"James", "lastName": "Halpert"}' response.txt
cat response.txt
echo

echo
aws lambda invoke --function-name bash-runtime2 --payload '{"firstName":"James", "lastName": "Jamm"}' response.txt
cat response.txt
echo

dump

cat target/*.log
