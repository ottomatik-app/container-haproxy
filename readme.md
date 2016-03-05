# ottomatik/haproxy

Docker configuration based on `dockercloud/haproxy` which adds dynamic DNS update
capability for AWS Route 53.

The following environment variables are required to be set once.

* `AWS_ACCESS_KEY_ID` - aws access key
* `AWS_SECRET_ACCESS_KEY` - aws secret key
* `AWS_DEFAULT_REGION` - default region for aws communication
* `R53_ZONEID` - the Route 53 zone ID to update

For each DNS record you want to update add environment variables
with an enumeration indicator in the variable as follows (you want
3 variables for each recordset):

* `R53_RS_NAME_1`
* `R53_RS_TYPE_1`
* `R53_RS_TTL_1`
