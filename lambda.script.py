
import subprocess
import boto3
import urllib.request


a = 'https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip'

urllib.request.urlretrieve(a, arc)




def runner(*args):
        v = []
        for i in args:
                v.append(i)
        a = subprocess.Popen(v, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
        e,o = a.communicate()
        if e != None:
                print('The error has occured: ' + e)
        print(o)


def lambda_handler(event, context):
        runner('unzip', 'arc')
        runner('mv', 'terraform', '/usr/local/bin/')
        runner('terraform', '--version')

        runner("wget", "https://s3.ca-central-1.amazonaws.com/terraform.backups.lambda/test.tf")

        runner("terraform", "apply", "test.tf")


