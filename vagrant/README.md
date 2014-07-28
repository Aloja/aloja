## Howto build management certificate keys for Vagrant

1. Create RSA private key  
`openssl genrsa -out management.key 2048`  

2. Create a self signed certificate  
`openssl req -new -key management.key -out management.csr`  

3. Create the management.pem x509 pem file from RSA key created in Step 1 and the self signed certificate created in Step 2  
`openssl x509 -req -days 365 -in management.csr -signkey management.key -out management.pem`  

4. Concatenate the management PEM file and RSA key file to a temporary .pem file. This file will be used to create the Management Certificate file you will upload to the Azure Portal  
`cat management.key management.pem > mgmkey.pem`

5. Create the Management Certificate file. This will be the Management Certificate .cer file you need to upload to the Management Certificates section of the Azure portal.  
`openssl x509 -inform pem -in mgmkey.pem -outform der -out management.cer`

Upload management.cer to your Windows Azure account, and use the "mgmkey.pem" file as your management certificate for Vagrant.

*Kudos to https://github.com/pkgcloud/pkgcloud/blob/master/docs/providers/azure.md#azure-management-certificates*
