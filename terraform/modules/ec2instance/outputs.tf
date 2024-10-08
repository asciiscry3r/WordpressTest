// Copyright (C) 2022 by Klimenko Maxim Sergeevich

#output "public_ip" {
#  value = aws_instance.server.public_ip   
#}

output "server_security_group_id" {
  value = aws_security_group.server.id
}