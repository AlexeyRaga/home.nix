{ ... }:
let
  awsRdsBundle = builtins.fetchurl {
    name = "aws-rds-pki-bundle.pem";
    url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem";
    sha256 = "sha256:13yvbh6lj7g1zyvcl7jbncjy6dcz1q5sx824w2vf53yllpm928fp";
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
