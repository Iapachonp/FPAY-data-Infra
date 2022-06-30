import pandas as pd 
import datetime
from google.cloud import storage
import base64

def download_csv():
    df = pd.read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/live/us-states.csv')
    return (df.to_csv(index=False))

def upload_csv(blob_name, file, bucket_name):
    # Implicitly use service account credentials with environment credentials
    storage_client = storage.Client()
    #print(buckets = list(storage_client.list_buckets())
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.upload_from_string(file)
    
    #returns a public url
    return blob.public_url


def main_pub_sub(event, context):
    if 'data' in event:
        name = base64.b64decode(event['data']).decode('utf-8')
        print('getting data from {}'.format(name))
        file_name="csv_covid_ingestion_{}".format(datetime.datetime.now())
        upload_csv(file_name, download_csv(), "dataops-test-7e904d691bf2")
    else:
        print('No data in the message')
        
    
    