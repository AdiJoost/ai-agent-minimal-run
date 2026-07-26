# ai-agent-minimal-run

A minimal setup for running an AIT agent with Docker or Apptainer.

## Run with Docker Compose

The easiest way to start the AI agent is with Docker Compose. This requires a running Docker Engine. Docker Desktop is recommended; you can install it from the official Docker documentation.

Before you begin, make sure Docker is actually running.

Navigate to the aitagent folder in this repository:

```bash
cd aitagent
```

Start the system with:

```bash
docker-compose up -d
```

You should see the required images being pulled from Docker Hub, followed by a confirmation that the three containers (ollama, aitagent, and aitmcpserver) have started.

The server listens on http://localhost:8080/api/run. Trigger the run by sending a POST request to this endpoint.

For example, in PowerShell:

```powershell
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/run"
```

This request does not return a response body, but it starts the internal execution. This approach was chosen because the container starts a web server intended to listen for a WebSocket in production. Running run.py directly would result in an unfavorable Docker image. Docker Compose, however, makes the whole system deployable with a single file and two commands.

### Configure Test Execution

The setup is easy to start, but it does not allow you to configure custom system prompts. You can only change the model by updating the agent_model value in .serverenv. You may choose any model available in Ollama.

To define the test cases the agent should process:

- Add the test cases to the data/testcases_to_update folder.
- Add the corresponding solutions to the data/solutions folder.

### Notes

Be aware that when the system is started with Docker Compose, the AI agent runs on your local machine and therefore needs sufficient computational resources to host the selected model. Depending on your hardware and the chosen test configuration, execution may take some time.

Some networks may drop packets for the AIT images. The images were tested in the FHGR network, so if you encounter pull errors, try connecting through the VPN. If the network settings of the FHGR network change, image availability may also change.

If you want to have a richer logging and see the steps or messages of the agent, change the LOG_LEVEL in the .env file to "INFO" or "DEBUG"

## Run on the FHGR Workstation with Apptainer

To test larger models, you can run the system using the two Bash scripts provided in this repository.

The setup works similarly to Docker Compose, but it also lets you choose the prompting strategies to test. To do so, edit the file config/prompt_candidates.json.

Once you are happy with the configuration, copy the aitagent folder to the server.

For example:

```bash
tar -cvf aitagent.tar ./aitagent
```

Then transfer it to the server:

```bash
scp aitagent.tar <your_username>@nickel.fhgr.ch:<your_path>/.aitagent.tar
```

Unpack the archive and move into the folder:

```bash
tar -xvf aitagent.tar
cd aitagent
```

Make the scripts executable and install the application using the desired versions of the agent and MCP server:

```bash
chmod +x run-apptainer.sh build-apptainer.sh
./build-apptainer.sh <aitagent-version> <aitmcpserver-version>
```

The data files of the test results indicate which versions were used for the agent and MCP server. In most cases, it is recommended to use the latest tag for both:

```bash
./build-apptainer.sh latest latest
```

When the setup is ready, start the test run:

```bash
./run-apptainer.sh <FILE_OFFSET> <FILE_OFFSET_END>
```

Use FILE_OFFSET to skip the first n test cases, and FILE_OFFSET_END to stop after a specific position in the file list. For example, ./run-apptainer.sh 4 6 tests the agent using the test cases at positions 4 and 5 in the file system. This makes it possible to run parallel executions.

### Notes

On FHGR workstations, you need to request GPUs through Slurm. Also note, that in the .env file, the current model is gemma4:latest, which results to gemma4:e4b, small enough to be run on a phone. To use the model used in the Bachelor Thesis, change this to gemma4:31b. The smaller model was set in this .env file, as when run with docker, the bigger model could fail due to lack of computational power on a local machine.
