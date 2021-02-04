import logging
import boto3
from botocore.exceptions import ClientError
from os import listdir
import pandas as pd


def read_csv_from_s3(s3_path):
    """Read a csv file by a s3 path

    :param s3_path: s3 path of the csv file to be read
    """
    data = pd.read_csv(s3_path)
    return data

def upload_csv_to_s3(df,s3_path):
    """Upload a csv by a s3 path

    :param s3_path: s3 path of the file to be uploaded
    """
    try:
        df.to_csv(s3_path, index=False)
        return True
    except:
        return False