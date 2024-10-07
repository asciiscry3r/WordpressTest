// Copyright (C) 2022 by Klimenko Maxim Sergeevich

#output "public_ip" {
#  value = aws_instance.server[0].public_ip   
#}