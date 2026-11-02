# Ajusta el endpoint al que usaste en tus prácticas anteriores
$endpoint = "http://localhost:4566"
$region   = "us-east-2"

# 1. Crear el topic
$topicArn = aws sns create-topic --name topico-polizas `
  --endpoint-url $endpoint --region $region `
  --query TopicArn --output text

# 2. Crear dos colas
foreach ($q in "cola-facturacion", "cola-notificaciones") {
    aws sqs create-queue --queue-name $q `
      --endpoint-url $endpoint --region $region | Out-Null
}

# 3. Suscribir cada cola al topic
foreach ($q in "cola-facturacion", "cola-notificaciones") {
    $url = aws sqs get-queue-url --queue-name $q `
      --endpoint-url $endpoint --region $region `
      --query QueueUrl --output text

    $qArn = aws sqs get-queue-attributes --queue-url $url `
      --attribute-names QueueArn `
      --endpoint-url $endpoint --region $region `
      --query Attributes.QueueArn --output text

    aws sns subscribe --topic-arn $topicArn `
      --protocol sqs --notification-endpoint $qArn `
      --endpoint-url $endpoint --region $region | Out-Null
}

# 4. Publicar UN mensaje
aws sns publish --topic-arn $topicArn `
  --message "Poliza 12345 emitida" `
  --endpoint-url $endpoint --region $region

# 5. Verificar que llegó a AMBAS colas
foreach ($q in "cola-facturacion", "cola-notificaciones") {
    Write-Host "--- $q ---"
    $url = aws sqs get-queue-url --queue-name $q `
      --endpoint-url $endpoint --region $region `
      --query QueueUrl --output text
    aws sqs receive-message --queue-url $url `
      --endpoint-url $endpoint --region $region
}