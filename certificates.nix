{ ... }:
let
  awsRdsBundle = builtins.fetchurl {
    name = "aws-rds-pki-bundle.pem";
    url = "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem";
    sha256 = "sha256:1qy7wfflywb6wh362r4i1dzycpmi1vmgvgy9l6yqfl7lrj221fz5";
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
