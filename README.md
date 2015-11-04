# AWS CodePipeline Buildkite Custom Action Type

An example custom action type for triggering Buildkite builds from within AWS CodePipeline.

## Getting Started

To add a custom type to CodePipeline you need to use the [aws cli tool](https://aws.amazon.com/cli/), so make sure you have this installed and authorized to modify CodePipeline service. You can test if the cli is configured by running `aws codepipeline list-pipelines`.

You'll also need [jq](https://stedolan.github.io/jq/) installed.

### Add a new custom type to CodePipeline

Create a Buildkite custom action type using one of the example JSON definitions. There are separate JSON files for each of the types:

* [`Source`](custom-action-types/source.json)
* [`Build`](custom-action-types/build.json)
* [`Test`](custom-action-types/test.json)
* [`Deploy`](custom-action-types/deploy.json)

For example, use the following command command to create a Buildkite `Test` and Buildkite `Deploy` action type:

```bash
aws codepipeline create-custom-action-type --cli-input-json file://custom-action-types/test.json
```

### Edit your pipeline

...

### Create a release

...

### Run the job poller

...

```bash
$ ./poll.sh "category=Test,owner=Custom,version=1,provider=Buildkite"
Polling for CodePipeline job for action-type-id 'category=Test,owner=Custom,version=1,provider=Buildkite'
Found job. Creating build at https://api.buildkite.com/v1/organizations/myorg/projects/myproj/builds
Build #398 created - https://buildkite.com/myorg/myproj/builds/398
Acknowleding CodePipeline job (id: e3d5097b-5933-438d-af73-56d9eb0d5a41 nonce: 3)
```