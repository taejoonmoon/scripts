from __future__ import print_function

from pprint import pprint
from unicodedata import name

import pandas as pd
from googleapiclient import discovery
from oauth2client.client import GoogleCredentials

creds = GoogleCredentials.get_application_default()
service = discovery.build('dns', 'v1', credentials=creds)
project = ''

def delete_all_dns():
    request = service.managedZones().list(project=project)
    response = request.execute()
    
    for managed_zone in response['managedZones']:
        delete_all_records(managed_zone['name'])
        delete_dns(managed_zone['name'])

def delete_dns(managed_zone):
    request_delete = service.managedZones().delete(project=project, managedZone=managed_zone['name'])
    request_delete.execute()

def delete_all_records(managed_zone):
    request = service.resourceRecordSets().list(project=project,
                                            managedZone=managed_zone)
    response = request.execute()
    for record_set in response['rrsets']:
        delete_record(record_set, managed_zone)

def delete_record(record_set, managed_zone):
    if record_set['type'] != "NS" and record_set['type'] != "SOA":
        request_delete = service.resourceRecordSets().delete(
            project = project,
            managedZone=managed_zone,
            name=record_set['name'],
            type=record_set['type']
        )

        request_delete.execute()