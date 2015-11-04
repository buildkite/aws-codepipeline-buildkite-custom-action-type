# Using AWS CodePipeline with Buildkite

All you need to trigger Buildkite builds from [AWS CodePipeline](https://aws.amazon.com/codepipeline/) tasks: a set of [custom-action-type JSON files](custom-action-types) you upload via the AWS CLI, and a [custom checkout agent hook](agent-hooks/checkout) that uses the CodePipeline S3 artifact instead of git.

<img src="http://i.imgur.com/sgel4lR.png" width="242">

## Requirements

* [aws cli tool](https://aws.amazon.com/cli/)<br>You can test if the cli is configured by running `aws codepipeline list-pipelines`
* [jq](https://stedolan.github.io/jq/)
* A Buildkite [API access token](https://buildkite.com/docs/api#authentication) with the `read_builds` and `write_builds` scope

## Setup

### 1. Create your project on Buildkite

Create your project and steps as you normally would, but you don't need to a valid git repository URL as the source code will be downloaded via the CodePipeline's S3 bucket.

### 2. Add a new custom type to CodePipeline

The only way to create a custom CodePipeline action type is via the aws cli. There are separate JSON files for each of the types [`Source`](custom-action-types/source.json), [`Build`](custom-action-types/build.json), [`Test`](custom-action-types/test.json) and [`Deploy`](custom-action-types/deploy.json)

The following command creates a custom action type for a Buildkite `Test` action:

```bash
aws codepipeline create-custom-action-type --cli-input-json file://custom-action-types/test.json
```

### 3. Use the task in your pipeline

Add a new pipeline action:

<img src="http://i.imgur.com/2ItTqhq.png" width="197">

Choose the type you created earlier:

<img src="http://i.imgur.com/EJoLV8R.png" width="548">

Configure it with your Buildkite details:

<img src="http://i.imgur.com/hfiyBEa.png" width="542">

### 2. Start a Buildkite agent with the customized checkout hook

```bash
buildkite-agent start --token xxx \
                      --hooks-path "$PWD/agent-hooks" \
                      --meta-data codepipeline=true
```

### 3. Run the CodePipeline job poller

```
$ ./poll.sh "category=Test,owner=Custom,version=1,provider=Buildkite"
Polling for CodePipeline job for action-type-id 'category=Test,owner=Custom,version=1,provider=Buildkite'
```

### 5. Create a release

Create a new release on CodePipeline, either with the "Release change" button or via the cli like so:

```
aws codepipeline start-pipeline-execution --name my-pipeline
```

Your job poller should pick up the job, create a Buildkite build, and report back on the status:

```
Found job. Creating build at https://api.buildkite.com/v1/organizations/myorg/projects/myproj/builds
Build #398 created - https://buildkite.com/myorg/myproj/builds/398
Acknowleding CodePipeline job (id: e3d5097b-5933-438d-af73-56d9eb0d5a41 nonce: 3)
Build is running
Build is running
Build finished
Updating CodePipeline job with 'passed' result
```

Your pipeline should now show the completed task, with a link to the successful Buildkite build:

<img src="http://i.imgur.com/sgel4lR.png" width="242">

:tada:

## License

See [LICENSE](LICENSE) (MIT)
