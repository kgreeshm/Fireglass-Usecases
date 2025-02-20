output "ASA-Public-IP" {
  value = aws_instance.asav.*.public_ip
}