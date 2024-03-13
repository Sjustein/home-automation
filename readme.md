This repo is a fork of rajbos' home-automation repo and contains a simplified version of the camera status synchronization script to homeassistant. It just syncs the status of a boolean helper in homeassistant so you can customize what happens by automations.
This makes the code more flexible and should be easier to implement into your homeassistant workflow.


# Trigger a home assistant scene on unlock (Windows)
When I log in to my laptop, run `camera-check.ps1` script and trigger a scene on my [home assistant](https://www.home-assistant.io/).
Note 1: Set up with Windows Task schedular to only run the script when connected on the home WIFI.

Scripts:
1. camera-check.ps1: Run this script to start monitoring the camera. It can be [started at user login](https://www.howtogeek.com/141894/how-to-use-powershell-to-detect-logins-and-alert-through-email/).
1. trigger-homeassistant.ps1: Run this script to trigger events on home-assistant.
1. utils.ps1: Some useful functions to add a timestamp to the log output.

# Detecting camera is being used (Windows)
In the script `camera-check.ps1` I have a couple of methods to check if you are using the camera. Any process should be picked up, as long as you run the script with admin rights (elevated). This is needed because a lot of applications (like the camera app, slack, usage in a browser) don't take control of the camera directly, but through svchost.exe.

## LoopWithAction
Call `LoopWithAction` to check if the camera is being used, and if so, run the action. This method will stop checking after the first 'in use' result and run the action. It will then wait for the remaining of half a minute before checking again (to prevent checking to often, but still switching the lights relatively quickly).

For the action, update the method 'Run-Action' to your liking. I have a check in there to only send in an update to Home Assistant if needed, but you can do whatever you want here.

# Tested succesfully in action with:
- Teams
- Windows camera
