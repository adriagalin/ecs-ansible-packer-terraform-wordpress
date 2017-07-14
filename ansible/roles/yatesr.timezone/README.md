Role Name
========

timezone

Role Variables
--------------
```

# Default timezone.  Must be a valid tz database time zone.
timezone: UTC

```

Example Playbook
-------------------------
### playbook.yml

```

---
- hosts: all
  roles:
  - timezone

  vars:
   timezone: America/New_York

```

License
-------

Apache 2.0

Author Information
------------------

Ryan Yates
