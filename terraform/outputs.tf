output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "application_private_ip" {
  value = aws_instance.application.private_ip
}

output "database_private_ip" {
  value = aws_instance.database.private_ip
}

output "vpc_id" {
  value = aws_vpc.blog_vpc.id
}