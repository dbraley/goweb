#!/bin/bash

FAILURE_COUNT=0

function assertEquals {
    DESCRIBE=$1
    EXPECTED=$2
    ACTUAL=$3

    #echo "Comparing $ACTUAL =?= $EXPECTED"
    if [ $EXPECTED != $ACTUAL ] ; then
        ((FAILURE_COUNT++))
        echo "Failure-$FAILURE_COUNT: Expected $DESCRIBE to be $EXPECTED, was: $ACTUAL"
    fi
}

go install
goweb & APP_PID=$!
echo "goweb pid: $APP_PID"

# Give server a moment to init
sleep 1

INDEX_SIZE=`curl -s localhost:8000/people | jq -r '. | length'`

assertEquals "size of initial index" 3 $INDEX_SIZE

KOKO_DOE=`curl -s localhost:8000/people/2`

assertEquals "index 2 first name" "Koko" `jq -r '.firstname' <<< "$KOKO_DOE" `

INDEX_AFTER_POST=`curl -s -X POST -d '{"id":"4", "firstname":"George", "lastname":"Washington"}' localhost:8000/people/4`

assertEquals "size of index after 1 addition" 4 `jq -r '. | length' <<< "$INDEX_AFTER_POST" `

GEORGE_WASHINGTON=`curl -s localhost:8000/people/4`

assertEquals "index 4 first name" "George" `jq -r '.firstname' <<< "$GEORGE_WASHINGTON" `

AFTER_DELETE=`curl -s -X DELETE localhost:8000/people/4`

assertEquals "size of index after 1 addition" 3 `jq -r '. | length' <<< "$AFTER_DELETE" `


kill -9 $APP_PID

echo "There were $FAILURE_COUNT Failures"

exit $FAILURE_COUNT