# README

## Overview

This script will get the signed in users current "Presence" (as defined by Teams/Skype) and if that user is in a call, do some action

This particular "do some action" is to scroll a message across the LCD screen on an installed [Sense Hat](https://www.raspberrypi.org/products/sense-hat/)



### Authentication

If a valid user authentication token is not present in cache, one will need to be created. A couple options are available for this.

If the script is run manually on the intended device, it will open an authentication window in the default web browser and prompt the user to enter a code and sign in.  This will create an auth token that can automatically refresh for some time going forward.

If the user needs a method of being notified of an expired or invalid auth token without interfacing with their device, I propose the following solution:

If no valid token, send a message to Azure Service Bus Queue.  Build a Logic App that listens to that Queue and sends an email to the address listed in config.json with the auth code required.

Templates for both of the required resources are included in this repo under the `Azure` folder. Configuration instructions are included further down this README.



## Prerequisites

Script built and tested in **Python 3.7**

First, install the required packages using `pip3 install requirements.txt`

Some users may have difficulty installing the `azure-servicebus` package.  This is often a result of non-native support for UAMQP on Raspbian.  Installing the packages called out in the [UAMQP pypi page](https://pypi.org/project/uamqp/) should resolve the issue.

Alternatively, if you don't plan on setting up Azure infrastructure for supplying an email notification, simply remove azure-servicebus from requirements.txt. It is not needed in this case.

Create a config.json file with the following structure, filling in the empty attributes (if you don't plan on setting up Azure infrastructure, remove `email`, `sb_queue`, `sb_queue_policy`, and `sb_sakey`):
```
{
    "authority": "https://login.microsoftonline.com/common",
    "client_id": "",
    "scope": ["Presence.Read Presence.Read.All"],
    "endpoint": "https://graph.microsoft.com/beta/me/presence",
    "email": "",
    "sb_queue": "",
    "sb_queue_policy": "",
    "sb_sakey": ""
}
```

