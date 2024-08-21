# Saídas para exibir o URL da API Gateway

output "api_url" {
  description = "URL da API Gateway para o recurso /sobreviventes"
  value = "${aws_api_gateway_stage.apigw_stage.invoke_url}/sobreviventes"
}