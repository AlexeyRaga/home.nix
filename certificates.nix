{ ... }:
let
  awsRdsBundle = builtins.fetchurl {
    name = "aws-rds-pki-bundle.pem";
    url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem";
    sha256 = "sha256:186jayjyx9jf07ljrh3vx38r1qpbppf4zrwxf7v9x3nlxml1f59c";
  };
  awsRedshiftBundle = builtins.fetchurl {
    name = "aws-redshift-pki-bundle.pem";
    url = "https://s3.amazonaws.com/redshift-downloads/amazon-trust-ca-bundle.crt";
    sha256 = "sha256:0l6mbg5jmpl4fy25di71jaxvq09kjs9qh5b0km5x2704p3jainrn";
  };
in
{
  security.pki.certificateFiles = [
    awsRdsBundle
    awsRedshiftBundle
  ];
}
