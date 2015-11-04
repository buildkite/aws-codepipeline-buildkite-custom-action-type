# AWS CodePipeline Buildkite Custom Action Type

An example of a custom action type, and a customized Buildkite agent checkout hook, for running Buildkite builds from [AWS CodePipeline](https://aws.amazon.com/codepipeline/).

Contains:

* [agent-hooks](agent-hooks) - a checkout agent hook override that downloads the source code via the CodePipeline S3 artifact
* [custom-action-types](custom-action-types) - sample custom action type JSON files that can be uploaded via the AWS CLI

Requirements:

* [aws cli tool](https://aws.amazon.com/cli/) (you can test if the cli is configured by running `aws codepipeline list-pipelines`)
* [jq](https://stedolan.github.io/jq/)
* A Buildkite API access token with the `read_builds` and `write_builds` scope

## Setup

### 1. Start a Buildkite agent with the customized checkout hook

```bash
buildkite-agent start --token xxx \
                      --hooks-path "$PWD/agent-hooks" \
                      --meta-data queue=codepipeline
```

### 2. Add a new custom type to CodePipeline

The only way to create a custom CodePipeline action type is via the aws cli. There are separate JSON files for each of the types [`Source`](custom-action-types/source.json), [`Build`](custom-action-types/build.json), [`Test`](custom-action-types/test.json) and [`Deploy`](custom-action-types/deploy.json)

The following command creates a custom action type for a Buildkite `Test` action:

```bash
aws codepipeline create-custom-action-type --cli-input-json file://custom-action-types/test.json
```

### 3. Edit your pipeline

Add a new pipeline action:

<img src="http://i.imgur.com/2ItTqhq.png" width="197">

Choose the type you created earlier:

<img src="http://i.imgur.com/EJoLV8R.png" width="548">

Configure it with your Buildkite details:

<img src="http://i.imgur.com/hfiyBEa.png" width="542">

### 4. Create a release

Create a new release, and then run the job poller:

```bash
$ ./poll.sh "category=Test,owner=Custom,version=1,provider=Buildkite"
Polling for CodePipeline job for action-type-id 'category=Test,owner=Custom,version=1,provider=Buildkite'
Found job. Creating build at https://api.buildkite.com/v1/organizations/myorg/projects/myproj/builds
Build #398 created - https://buildkite.com/myorg/myproj/builds/398
Acknowleding CodePipeline job (id: e3d5097b-5933-438d-af73-56d9eb0d5a41 nonce: 3)
Build is running
Build is running
Build finished
Updating CodePipeline job with 'passed' result
```

<img src="http://i.imgur.com/sgel4lR.png" width="242">
