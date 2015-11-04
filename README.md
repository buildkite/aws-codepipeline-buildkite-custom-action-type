# AWS CodePipeline Buildkite Custom Action Type

An example custom action type for triggering Buildkite builds from within AWS CodePipeline.

Requirements:

* [aws cli tool](https://aws.amazon.com/cli/) (you can test if the cli is configured by running `aws codepipeline list-pipelines`)
* [jq](https://stedolan.github.io/jq/)
* A Buildkite API access token with the `read_builds` and `write_builds` scope

### Add a new custom type to CodePipeline

Create a Buildkite custom action type using one of the example JSON definitions. There are separate JSON files for each of the types:

* [`Source`](custom-action-types/source.json)
* [`Build`](custom-action-types/build.json)
* [`Test`](custom-action-types/test.json)
* [`Deploy`](custom-action-types/deploy.json)

For example, use the following command command to create a Buildkite `Test` action type:

```bash
aws codepipeline create-custom-action-type --cli-input-json file://custom-action-types/test.json
```

### Edit your pipeline

Add a new pipeline action:

<img src="http://i.imgur.com/2ItTqhq.png" width="197">

Choose the type you created earlier:

<img src="http://i.imgur.com/EJoLV8R.png" width="548">

Configure it with your Buildkite details:

<img src="http://i.imgur.com/hfiyBEa.png" width="542">

### Create a release

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
Updating CodePipeline job with 'failed' result
```

<img src="http://i.imgur.com/sFcKQys.png" width="236">

## TODO

* Revision/commit isn't passed correctly through to Buildkite
