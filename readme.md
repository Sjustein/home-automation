This repo is a fork of rajbos' home-automation repo and contains a simplified version of the camera status synchronization script to homeassistant. It just syncs the status of a boolean helper in homeassistant so you can customize what happens by automations.
This makes the code more flexible and should be easier to implement into your homeassistant workflow.

# How to set up
First, clone this repository and configure powershell to allow it to run these scripts, if that isn't set already.

- Download [the handle executable](https://learn.microsoft.com/en-us/sysinternals/downloads/handle) from the official microsoft download page and extract its contents to the `Handle` directory in this folder.
- Copy .env.example to .env and fill in the required parameters (HOMEASSISTANT, ENTITY and SLEEP)
- Run camera-check.ps1 manually once, to set the homeassistant API key. Refer to the [homeassistant documentation](https://developers.home-assistant.io/docs/api/rest/) to create an API key. The user of which you create an API key must be an administrator on your homeassistant instance.
- Check the output for any errors. Especially the errors related to home assistant are very verbose.
- Read the rest of the readme for more context and optional additional setup steps.

# Update a home assistant entity (Windows)
When I log in to my laptop, windows task scheduler runs `camera-check.ps1` script and sets the value of my boolean helper entity on my [home assistant](https://www.home-assistant.io/).
Note 1: Set up with Windows Task schedular to only run the script when connected on the home WIFI.

Scripts:
1. camera-check.ps1: Run this script to start monitoring the camera. It can be [started at user login](https://www.howtogeek.com/141894/how-to-use-powershell-to-detect-logins-and-alert-through-email/).
2. trigger-homeassistant.ps1: Run this script to trigger events on home-assistant.
3. utils.ps1: Some useful functions to add a timestamp to the log output.
4. import-env.ps1: Functions to parse the .env file into $env

# Detecting camera is being used (Windows)
In the script `camera-check.ps1` I have a couple of methods to check if you are using the camera. Any process should be picked up, as long as you run the script with admin rights (elevated). This is needed because a lot of applications (like the camera app, slack, usage in a browser) don't take control of the camera directly, but through svchost.exe.

## LoopWithAction
Call `LoopWithAction` to check if the camera is being used, and if so, run the action. This method will stop checking after the first 'in use' result and run the action. It will then wait for the remaining of half a minute before checking again (to prevent checking to often, but still switching the lights relatively quickly).

For the action, update the method 'Run-Action' to your liking. I have a check in there to only send in an update to Home Assistant if needed, but you can do whatever you want here.

# Environment variables
- HOMEASSISTANT: the homeassistant url to your instance
- ENTITY: the id of the entity in homeassistant (field Entity ID in homeassistant)
- SLEEP: the amount of seconds to sleep from the start of each webcam poll to the start of the next poll
- WEBCAM_FILTER: optional, does a wildcard search on the list of webcams found on your system. Might be useful when you have one webcam on which this should work. Additionally speeds up the script if you have a lot of webcams installed.

# Tested succesfully in action with (on windows 11, powershell 5.1):
- Teams
- Windows camera
