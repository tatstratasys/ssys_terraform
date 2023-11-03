#!/usr/bin/env python3

import json
import os
import sys
import flask
import logging
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("-f", "--filepath", default="instance-pricing.json", help="Path to the json file to serve as API server")
parser.add_argument("-p", "--port", default=9000, help="Set the port to publish the service, defaults to 9000")
parser.add_argument("-l", "--logpath", default="api.log", help="Set the log path")
parser.add_argument("-d", "--debug", default=False, help="Store data from volumes", action="store_true")

args = parser.parse_args()

print("Using data from " + args.filepath)

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(args.logpath),
        logging.StreamHandler()
    ]
)

flask_app = flask.Flask(__name__)

def read_json_file(filename):
    with open(filename, 'r') as fh:
        data = json.load(fh)
    return data


@flask_app.route("/")
def root():
    response = """
Information API
---------------

/v1
    - Version 1 of the APIs
"""
    return flask.Response(response, mimetype='text/plain')


@flask_app.route("/v1")
def v1info():
    response = """
Instance pricing API
--------------------

/v1/instance-type-info
    - List all the instance information

/v1/instance-type-info/<instance_type>
    - List the instance information for a given type
"""
    return flask.Response(response, mimetype='text/plain')


@flask_app.route("/v1/instance-type-info")
def all_info():
    return flask.Response(json.dumps(instance_pricing), mimetype='application/json')

@flask_app.route("/v1/instance-type-info/<instance_type>")
def single_info(instance_type):
    instances = [item for item in instance_pricing if item['instance_type'].startswith(instance_type)]
    return flask.Response(json.dumps(instances), mimetype='application/json')




instance_pricing = read_json_file(args.filepath)

if __name__ == '__main__':
    flask_app.run(debug=args.debug, host='0.0.0.0', port=args.port)
