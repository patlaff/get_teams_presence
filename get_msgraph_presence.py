import os
import sys
import json
import urllib
import webbrowser
import pyperclip
import requests
import msal
import atexit
import time
import logging
import socket
from azure.servicebus import QueueClient, Message
from sense_hat import SenseHat

logging.basicConfig(filename='presence.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

#import config
config = json.load(open('config.json'))

# Sense Hat stuff:
sense = SenseHat()
sense.low_light = True
red = (255,0,0)
blue = (0,0,255)
timer = 56
start_time = time.time()
elapsed_time = 0

# Establish or open token_cache.bin
cache = msal.SerializableTokenCache()
if os.path.exists('token_cache.bin'):
    cache.deserialize(open('token_cache.bin', 'r').read())
atexit.register(lambda:
    open('token_cache.bin', 'w').write(cache.serialize())
    if cache.has_state_changed else None
    )

# Establish GRAPH connection
app = msal.PublicClientApplication(
    config['client_id'], 
    authority=config['authority'],
    token_cache=cache
    )

result = None

# We now check the cache to see if we have some end users signed in before.
accounts = app.get_accounts()
if accounts:
    #logging.info('Account in cache: %s',accounts[0]['username'])
    chosen = accounts[0]
    # Now let's try to find a token in cache for this account
    result = app.acquire_token_silent(config['scope'], account=chosen)

# If no accounts with valid token found in cache, prompt user to log in again and get new
if not result:
    logging.info("No suitable token exists in cache. Let's get a new one from AAD.")

    flow = app.initiate_device_flow(scopes=config['scope'])
    if 'user_code' not in flow:
        e = f'Failed to create device flow. Err: {json.dumps(flow, indent=4)}'
        logging.error(e)
        raise ValueError(e)
    else:
        if config['email']:
            msg = {}
            msg['message'] = f'Auth Token for {sys.argv[0]} on {socket.gethostname()} is not valid or unavailable. Please follow the link below and paste in the following code to generate a new token.'
            msg['email'] = config['email']
            msg['user_code'] = flow['user_code']
            msg['verification_uri'] = flow['verification_uri']
            msg_formatted = str(json.dumps(msg))
            message = Message(msg_formatted)
            try:
                queue_client = QueueClient.from_connection_string(f"Endpoint=sb://lafferty-notification-hub.servicebus.windows.net/;SharedAccessKeyName={config['sb_queue_policy']};SharedAccessKey={config['sb_sakey']};EntityPath={config['sb_queue']}")
                queue_client.send(message)
                logging.info('Message sent to SB Queue successfully - check email for auth code.')
            except Exception as e:
                logging.info(f'Error sending message to SB Queue : {e}')
        else:
            pyperclip.copy(flow['user_code']) # copy user code to clipboard
            webbrowser.open(flow['verification_uri']) # open browser
            logging.info('The code %s has been copied to your clipboard, and your web browser is opening %s. Paste the code to sign in.', flow['user_code'], flow['verification_uri'])

    result = app.acquire_token_by_device_flow(flow) 

if 'access_token' in result:
    # Calling graph using the access token
    graph_data = requests.get(  # Use token to call downstream service
        config['endpoint'],
        headers={'Authorization': 'Bearer ' + result['access_token']},).json()
    #print('Graph API call result: %s' % json.dumps(graph_data, indent=2))
else:
    logging.error(result.get('error'))
    logging.error(result.get('error_description'))
    logging.error(result.get('correlation_id'))  # You may need this when reporting a bug

# Parse Graph Response to get current User Activity
presence = graph_data['activity']
#logging.info('Activity : %s',presence)

# Activate lights on attached Sense Hat, and loop until next cron run
# Cron Schedule : * * * * *
if presence == 'InACall' or presence == 'InAConferenceCall':
    while elapsed_time < timer:
        sense.show_message('On Air', text_colour=blue, scroll_speed=0.2)
        current_time = time.time()
        elapsed_time = current_time - start_time
else:
    sense.clear()
     