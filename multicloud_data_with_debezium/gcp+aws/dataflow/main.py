#
# Leonardo Murillo <leonardo@murillodigital.com
# The following example is part of the Article Series "Multicloud Data with Debezium"
# visit https://www.murillodigital.com/tech_talk/multicloud_data_with_debezium_part3/
#
# This code can be used, modified and distributed as long as proper retribution exists.

from __future__ import print_function
import logging
import argparse
import json
import datetime

import apache_beam as beam

from apache_beam.options.pipeline_options import PipelineOptions, StandardOptions
from beam_nuggets.io import kafkaio
from functools import reduce
from bunch import bunchify

from google.cloud import bigquery

def rgetattr(obj, attr, *args):
    def _getattr(obj, attr):
        return getattr(obj, attr, *args)

    return reduce(_getattr, [obj] + attr.split('.'))


class Generic(object):
    @classmethod
    def from_dict(cls, dictionary):
        obj = cls()
        obj.__dict__.update(dictionary)
        return obj


class TransformSchema(beam.DoFn):
    def __init__(self, mapping_schema=dict(), *unused_args, **unused_kwargs):
        super().__init__(*unused_args, **unused_kwargs)
        self.mapping_schema = mapping_schema

    def transform_data(self, data):
        source_data = bunchify(json.loads(data[1], object_hook=Generic.from_dict))
        target_data = {}
        for mapping in self.mapping_schema:
            target = mapping
            source = self.mapping_schema.get(target)
            source_value = source(source_data) if callable(source) else rgetattr(source_data, source)
            target_data[target] = source_value
        return target_data

    def process(self, data):
        transformed_data = self.transform_data(data)
        return [transformed_data]


class Printer(beam.DoFn):
    def __init__(self, *unused_args, **unused_kwargs):
        super().__init__(*unused_args, **unused_kwargs)

    def process(self, data):
        logging.info("Data in the pipeline: {}".format(data))
        return data


class WriteToBigQuery(beam.DoFn):
    def __init__(self, dataset, project, table, *unused_args, **unused_kwargs):
        super().__init__(*unused_args, **unused_kwargs)
        self.dataset = dataset
        self.project = project
        self.table = table

    def start_bundle(self):
        self.bq_client = bigquery.Client()
        bq_dataset = self.bq_client.dataset(self.dataset, project=self.project)
        bq_table_ref = bq_dataset.table(self.table)
        self.bq_table = self.bq_client.get_table(bq_table_ref)

    def process(self, data):
        logging.info('Data in the writetobigquery method {}'.format(data))
        errors = self.bq_client.insert_rows(self.bq_table, [data])
        return data, errors


def run(bootstrap_servers, topic, project, dataset, table):
    kafka_config = {"topic": topic,
                    "bootstrap_servers": bootstrap_servers,
                    "group_id": "debezium_consumer_group"}

    mapping_schema = {
        "sku": lambda data: data.payload.after.sku if data.payload.op != 'd' else data.payload.before.sku,
        "name": lambda data: data.payload.after.name if data.payload.op != 'd' else data.payload.before.name,
        "price": lambda data: data.payload.after.price if data.payload.op != 'd' else data.payload.before.price,
        "quantity": lambda data: data.payload.after.available if data.payload.op != 'd' else data.payload.before.available,
        "timestamp": lambda data: datetime.datetime.utcfromtimestamp(data.payload.ts_ms / 1000).isoformat(),
        "deleted": lambda data: True if data.payload.op == 'd' else False
    }

    pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(StandardOptions).streaming = True

    p = beam.Pipeline(options=pipeline_options)

    _ = (p | 'Reading messages' >> kafkaio.KafkaConsume(kafka_config)
     | 'Preparing data' >> beam.ParDo(TransformSchema(mapping_schema))
     | 'Writing data to BigQuery' >> beam.ParDo(WriteToBigQuery(dataset, project, table)))
    result = p.run()
    result.wait_until_finish()


if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    parser = argparse.ArgumentParser()
    parser.add_argument('--bootstrap-servers', dest='bootstrap_servers', required=True)
    parser.add_argument('--topic', dest='topic', required=True)
    parser.add_argument('--project', dest='project', required=True)
    parser.add_argument('--dataset', dest='dataset', required=True)
    parser.add_argument('--table', dest='table', required=True)

    known_args, pipeline_args = parser.parse_known_args()

    run(known_args.bootstrap_servers, known_args.topic, known_args.project, known_args.dataset, known_args.table)
