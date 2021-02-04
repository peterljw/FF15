import s3fs

def upload_df_to_s3(df,s3_path):
    s3 = s3fs.S3FileSystem(anon=False)
    with s3.open(s3_path,'w') as f:
        df.to_csv(f)