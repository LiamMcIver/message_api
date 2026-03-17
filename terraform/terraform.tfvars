project     = "message-api"
environment = "dev"
location    = "westeurope"

subscription_id = "d6015d79-a228-435a-b5b4-05c83a11d1ca"

vnet_address_space               = ["10.0.0.0/16"]
subnet_function_integration_cidr = "10.0.1.0/24"
subnet_private_endpoints_cidr    = "10.0.2.0/24"
alert_email                      = "liammcivertest@gmail.com"

# Jumpbox access
jumpbox_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCiGpLgFKAPOK5jKbKeBeJZuesJYcr45ZmYbZpO2nTwbIJ2m7yl9Y7Vy/WiWrISaRzWVgK3jzz93jza4wwIg9d9KBQZa62C1zBILk+BaQEUVzAri4OsrUYdn6uuFSENPt+CJ/qWc9afytR4F/MC813LJvGJCS1H1xIyyv7bVSu5kuWDmspTSw6f9nCkiryBjyKqsLXYIuOKeR3s9Fz1owtGSA5SZXHwvQjDFjnBqnKIAVx6fw+CLefEj0jt/K+Q1krs+I0VJ8zK9lBk/de1g/TOw3KW8fd2y+3Ev/ZIktU1uSQEmy5fo8+9sDeGrHo/mTjBzNCuMaKpubBT+gVOW/jMtleWMizvl+9mxhHNEgKxEC/sS290SQIT19nXX1mkWWYrkfljOOaFKXCRmDrbFkMEhrTDsXnUO6YaH6DAQgRrPAx6C5YuhLzh07Nd5C6heVHpE0PfSZlXg2n7Pq+MOWLV6yxy2CSO8MSvQUoRzJ1f/KBfLVZ8DOWP717DvM83JairbmYIgVkZlqAg5iV3xYiausifFJMhAxWW1e0xAQbwJksAweEIO2T37oSh/irFCpao7xvXnRl/xqzotCpCsTvy3Ho88NpyJ0asyoLVzYGMjRr5Sk1wrrKPqGIQ5oYjC0pHMeg4TEGYXFArYxOB/YOXcnqIKIGgTHWDexAGceOXHw== admin@DESKTOP-AEVQ1J3"
jumpbox_allowed_ip     = "143.58.175.176/32"