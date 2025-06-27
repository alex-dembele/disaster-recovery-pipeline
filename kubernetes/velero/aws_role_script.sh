# Remplacez les variables
BUCKET_NAME=votre-bucket-velero-aws
OIDC_PROVIDER_URL=$(aws eks describe-cluster --name votre-cluster-eks --query "cluster.identity.oidc.issuer" --output text)
OIDC_PROVIDER_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/${OIDC_PROVIDER_URL#https://}"

# Créer la politique
cat > velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET_NAME}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET_NAME}"
            ]
        }
    ]
}
EOF
aws iam create-policy --policy-name VeleroAccessPolicy --policy-document file://velero-policy.json
POLICY_ARN=$(aws iam list-policies --query 'Policies[?PolicyName==`VeleroAccessPolicy`].Arn' --output text)

# Créer le rôle
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER_URL#https://}:sub": "system:serviceaccount:velero:velero"
        }
      }
    }
  ]
}
EOF
aws iam create-role --role-name VeleroRole --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name VeleroRole --policy-arn ${POLICY_ARN}