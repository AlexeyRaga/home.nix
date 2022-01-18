{ ... }:
let
  awsRdsBundle = builtins.fetchurl {
    name = "aws-rds-pki-bundle.pem";
    url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem";
  };
  awsRedshiftBundle = builtins.fetchurl {
    name = "aws-redshift-pki-bundle.pem";
    url = "https://s3.amazonaws.com/redshift-downloads/amazon-trust-ca-bundle.crt";
  };
in
{
  security.pki.certificateFiles = [
    awsRdsBundle
    awsRedshiftBundle
  ];
}
