import subprocess
import boto3
import os, ssl
import urllib
import zipfile


# Here, we specify main variables for the program d
# ( version of Terraform, directory it will be downloaded to,
# name of S3 bucket where the file is stored, name of the file etc)



ver = '0.12.7'

a = f'https://releases.hashicorp.com/terraform/{ver}/terraform_{ver}_linux_amd64.zip'

ter_dir = '/tmp/terraform'

BUCKET_NAME = 'Specify bucket name here'
OBJECT_NAME = 'architecture.tf'
FILE_NAME = 'terra_plan.tf'



#This function will be used to communicate with S3 and download files from it
def get_s3(arg1, arg2, arg3):
    s3 = boto3.client('s3')
    s3.download_file(arg1, arg2, f'{ter_dir}/{arg3}')



# The most important func which will be used to access the website
def get_terraform():

    # here we are forcing the system not to check the SSL for the Terraform website
    if (not os.environ.get('PYTHONHTTPSVERIFY', '') and getattr(ssl, '_create_unverified_context', None)):
        ssl._create_default_https_context = ssl._create_unverified_context


# Here we will create a directory for Terraform if it does not exist
    if not os.path.exists(ter_dir):
        os.mkdir(ter_dir)

    os.chdir(ter_dir)

#Here we download and unzip the Terraform archive along with a binary executable file
    urllib.request.urlretrieve(a, f'{ter_dir}/ter.zip')

# this part is used to unzip the downloaded file
    with zipfile.ZipFile(f'{ter_dir}/ter.zip', 'r') as zip_ref:
        zip_ref.extractall(f'{ter_dir}')

#Now we are using an S3 func created earlier to dowwload the main configuration file for Terraform & shell script

    get_s3(BUCKET_NAME, OBJECT_NAME, FILE_NAME)
    get_s3(BUCKET_NAME, 'shell.sh', 'shell.sh')

# This block is needed to catch any exceptions during running Linux commands ( via subprocess)
    try:
        subprocess.check_call(['chmod', '-R', '755', f'{ter_dir}'])
        subprocess.check_call([f'{ter_dir}/terraform', "init"])

        subprocess.check_call([f'{ter_dir}/terraform', "apply", '-input=false', '-auto-approve'])
    except subprocess.CalledProcessError as k:
        print(k.returncode)
        print(k.output)



# This function will be executed when the event is triggered
def lambda_handler(event, context):
    check = get_terraform()
    print(check)


