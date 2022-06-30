from google.cloud import bigquery
import os

def hello_gcs(event, context):
    """Background Cloud Function to be triggered by Cloud Storage.
       This generic function logs relevant data when a file is changed,
       and works for all Cloud Storage CRUD operations.
    Args:
        event (dict):  The dictionary with data specific to this type of event.
                       The `data` field contains a description of the event in
                       the Cloud Storage `object` format described here:
                       https://cloud.google.com/storage/docs/json_api/v1/objects#resource
        context (google.cloud.functions.Context): Metadata of triggering event.
    Returns:
        None; the output is written to Cloud Logging
    """

    print('Event ID: {}'.format(context.event_id))
    print('Event type: {}'.format(context.event_type))
    print('Bucket: {}'.format(event['bucket']))
    print('File: {}'.format(event['name']))
    print('Metageneration: {}'.format(event['metageneration']))
    print('Created: {}'.format(event['timeCreated']))
    print('Updated: {}'.format(event['updated']))

    # Construct a BigQuery client object.
    client = bigquery.Client()
    #set configurations
    project=os.getenv('GCP_PROJECT') or 'ipachon-test'
    table_id = f"{project}.dt_test.covid"
    #configure the schema 
    schema = [
        bigquery.SchemaField(mode = "NULLABLE",name= "date",field_type="DATE"),
        bigquery.SchemaField(mode = "NULLABLE",name= "state",field_type="STRING"),
        bigquery.SchemaField(mode = "NULLABLE",name= "fip",field_type="INTEGER"),
        bigquery.SchemaField(mode = "NULLABLE",name= "cases",field_type="INTEGER"),
        bigquery.SchemaField(mode = "NULLABLE",name= "deaths",field_type="INTEGER"),
    ]
    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV, skip_leading_rows=1, autodetect=True, write_disposition='WRITE_APPEND', schema=schema
    )
    uri=f"gs://{event['bucket']}/{event['name']}"
    #Load table to bigquery (append)
    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)  # Make an API request.
    load_job.result()  # Waits for the job to complete.
    destination_table = client.get_table(table_id)  # Make an API request.
    print("Loaded {} rows.".format(destination_table.num_rows))