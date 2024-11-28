aws iam list-users

aws iam list-groups

aws iam get-user --user-name User-1
aws iam get-user --user-name User-2
aws iam get-user --user-name User-3

aws iam get-group --group-name S3-Support
aws iam get-group --group-name EC2-Support
aws iam get-group --group-name EC2-Admin

aws iam list-attached-group-policies --group-name S3-Support
aws iam list-attached-group-policies --group-name EC2-Support
aws iam list-attached-group-policies --group-name EC2-Admin

aws iam get-policy --policy-arn <policy-ARN>

aws iam add-user-to-group --user-name User-1 --group-name S3-Support
aws iam add-user-to-group --user-name User-2 --group-name EC2-Support
aws iam add-user-to-group --user-name User-3 --group-name EC2-Admin
