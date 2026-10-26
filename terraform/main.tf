resource "local_file" "iot_config" {
  filename        = "${path.module}/iot_config.env"
  content         = "PORT=1883\nBROKER=MQTT\n"
  file_permission = "0644"
}
