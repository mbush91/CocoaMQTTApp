# CocoaMQTTApp

Sample shows setting up TLS with a cert.pem, key.pem, and ca.pem such as provided by AWS.

Note: This sample used a client id with certificates, not a username and password.

## Setup

Do a `pod install` then open the prject from the .xcworkspace

## Set Connection Info

Set up host, clientID, and certPassword in MQTTManager.swift

## Make P12 for Cert and Key

- USING OPENSSL@1.1
- Give password: somepassword (iOS cannot have an empty one)
`openssl pkcs12 -export -clcerts -in client-cert.pem -inkey client-key.pem -out client.p12`

## Make DER for the root CA

`openssl x509 -in your_ca.pem -outform der -out client.der`
