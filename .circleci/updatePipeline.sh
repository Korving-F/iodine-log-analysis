# Full Build Creation (Needed with workflow orchestration)
#curl --user ${CIRCLE_TOKEN}: \
#     --request POST \
#     --form revision=93227bb5d358f49f4764cc4e0341e602e2fefc5f \
#       https://circleci.com/api/v1.1/project/github/Korving-F/thesis-cicd-examples/build


# Simple job trigger
curl --user ${CIRCLE_TOKEN}: \
     --form config=@config.yml \
     --form notify=false \
     --form revision=f8e527e1c2b79f6c0c68761018dc3e3e4b08b0c0 \
     --form build_parameters[CIRCLE_JOB]=build-fixtures \
     --request POST "https://circleci.com/api/v1.1/project/github/Korving-F/iodine-log-analysis/tree/master"
