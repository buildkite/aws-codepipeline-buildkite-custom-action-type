#!/bin/bash

set -eu

if [[ -z "${1:-}" ]]; then
  echo "Usage: ./poll.sh <action type id>" >&2
  echo -e "Example:\n  ./poll.sh \"category=Test,owner=Custom,version=1,provider=Buildkite\"" >&2
  exit 1
fi

run() {
  local action_type_id="$1"

  while :
  do
    local job_json="$(fetch_job "$action_type_id")"

    if [[ "$job_json" != "null" ]]; then
      local build_json=$(create_build "$job_json")

      echo "Build created: $(echo "$build_json" | jq -r '.web_url')" >&2

      acknowledge_job "$job_json"

      wait_for_build_to_finish "$job_json" "$build_json"
    else
      sleep 1
    fi
  done
}

fetch_job() {
  local action_type_id="$1"

  echo "Waiting for CodePipeline job for action-type-id '$action_type_id'" >&2

  aws codepipeline poll-for-jobs --max-batch-size 1 \
                                 --action-type-id "$action_type_id" \
                                 --query 'jobs[0]'
}

action_configuration_value() {
  local job_json="$1"
  local configuration_key="$2"

  echo "$job_json" | jq -r ".data.actionConfiguration.configuration | .[\"$configuration_key\"]"
}

create_build() {
  local job_json="$1"

  local api_token=$(action_configuration_value "$job_json" "API-Access-Token")
  local org_slug="$(action_configuration_value "$job_json" "Organization-Slug")"
  local project_slug="$(action_configuration_value "$job_json" "Project-Slug")"
  local branch=$(action_configuration_value "$job_json" "Branch")
  local commit="$(echo "$job_json" | jq -r '.id')"
  local message="$(echo "$job_json" | jq -r '.data.pipelineContext.action.name')"

  local api_url="https://api.buildkite.com/v1/organizations/$org_slug/projects/$project_slug/builds"

  echo "Found job. Creating build at $api_url" >&2

  curl -s -H "Authorization: Bearer $api_token" "$api_url" \
    -X POST \
    --fail \
    -F "commit=$commit" \
    -F "branch=$branch" \
    -F "message=$message" \
    -F "env[CODEPIPELINE_JOB_JSON]=$(echo "$job_json" | jq -c '')"
}

acknowledge_job() {
  local job_json="$1"

  local job_id="$(echo "$job_json" | jq -r '.id')"
  local nonce="$(echo "$job_json" | jq -r '.nonce')"

  echo "Acknowledging CodePipeline job (id: $job_id nonce: $nonce)" >&2

  aws codepipeline acknowledge-job --job-id "$job_id" --nonce "$nonce" > /dev/null 2>&1
}

update_job_status() {
  local job_json="$1"
  local build_json="$2"

  local job_id="$(echo "$job_json" | jq -r '.id')"
  local build_state="$(echo "$build_json" | jq -r '.state')"
  local build_number="$(echo "$build_json" | jq -r '.number')"

  echo "Updating CodePipeline job with '$build_state' result" >&2

  if [[ "$build_state" == "passed" ]]; then
    aws codepipeline put-job-success-result \
      --job-id "$job_id" \
      --execution-details "summary=Build succeeded,externalExecutionId=$build_number,percentComplete=100"
  else
    aws codepipeline put-job-failure-result \
      --job-id "$job_id" \
      --failure-details "type=JobFailed,message=Build $build_state,externalExecutionId=$build_number"
  fi
}

wait_for_build_to_finish() {
  local job_json="$1"
  local build_json="$2"

  local build_url=$(echo "$build_json" | jq -r '.url')
  local api_token=$(action_configuration_value "$job_json" "API-Access-Token")

  while :
  do
    local latest_build_json=$(curl -s --fail -H "Authorization: Bearer $api_token" "$build_url")
    local finished_at="$(echo "$latest_build_json" | jq -r '.finished_at')"

    if [[ "$finished_at" != "null" ]]; then
      echo "Build finished" >&2
      update_job_status "$job_json" "$latest_build_json"
      break
    else
      echo "Build is running" >&2
      sleep 3
    fi
  done
}

run "$1"
