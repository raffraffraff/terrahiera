# Purpose
- Create Route53 delegation sets per apex zone
- Create Route53 zone record for each `apex_zone`, using delegation sets
- Create Route53 (optional) records in each zone, eg: SPF, DMARC, MX
- Output a map, with keys for each zone, and values:
 - zone ID
 - Delegation set ID
 - NS records

# Manual effort
Once the delegation sets are created, we can update the `name server` records for the domain on Namecheap. This is a manual step. However, we won't be destroying/creating delegation sets so the manual steps should be infrequent.
 
# Example input data (yaml)
```
apex_zones:
  "internal.net":
    comment: "Apex zone for internal services, requires VPN"
    tags: "%{alias('tags')}"
    force_destroy: false
  "production.com":
    comment: "Apex zone for production service, public"
    tags: "%{alias('tags')}"
    force_destroy: false
```

# Example output data (hcl)
```
apex_zones {
  internal.net {
    delegation_set_id = 12345
    zone_id           = ABCDEFG123456
    ns records        = [
                          ns1.awsdns-1.org,
                          ns1.awsdns-2.org,
                          ns1.awsdns-3.org,
                          ns1.awsdns-4.org
                        ]
  }
  production.net {
    delegation_set_id = 54321
    zone_id           = ABCDEFG123456
    ns records        = [
                          ns1.awsdns-10.org,
                          ns1.awsdns-20.org,
                          ns1.awsdns-30.org,
                          ns1.awsdns-40.org
                        ]
  }
}
```

## What about regional VPC zones?
The VPC component I wrote will create its own regional zones using the region-shortname, so for example in eu-west-1:
- ew1.internal.net
- ew1.production.com

...and the EKS cluster's External DNS / Cert Manager services would create records inside these depending on which ingress we choose:
- grafana.ew2.internal.net
- www.ew1.production.com

