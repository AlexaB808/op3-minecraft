output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft.id
}

output "public_ip" {
  description = "Public IP of the Minecraft server: SSH here from your laptop"
  value       = aws_instance.minecraft.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the Minecraft server"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.minecraft.public_ip}"
}

output "nmap_command" {
  description = "nmap command to verify Minecraft port: run this for the video demo"
  value       = "nmap -sV -Pn -p T:25565 ${aws_instance.minecraft.public_ip}"
}