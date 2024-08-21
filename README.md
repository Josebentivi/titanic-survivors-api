# Titanic Survivor Prediction API

Esta API utiliza machine learning para prever a sobrevivência de passageiros no naufrágio do Titanic. A API é construída utilizando o AWS API Gateway, Lambda, DynamoDB, Docker, Terraform e a documentação é fornecida no formato OpenAPI 3.0.

## Sumário
- [Descrição](#descrição)
- [Configuração e Instalação](#configuração-e-instalação)
- [Endpoints da API](#endpoints-da-api)
- [Agradecimentos](#agradecimentos)
- [Licença](#licença)

## Descrição

Esta API oferece endpoints para criar, listar, obter e excluir previsões de sobrevivência de passageiros do Titanic utilizando características como idade, tarifa, classe, etc.

## Configuração e Instalação

### Pré-requisitos
- Python 3.12
- AWS CLI configurado
- Docker
- Terraform

### Passos para Configuração

1. Clone o repositório:
    ```sh
    https://github.com/Josebentivi/titanic-survivors-api.git
    ```

2. Configure e ative seu ambiente virtual Python:
    ```sh
    python3 -m venv venv
    source venv/bin/activate
    ```

3. Instale as dependências:
    ```sh
    pip install -r lambda_function/requirements.txt
    ```

4. Configure suas credenciais AWS (Servidor localizado em São Paulo por conta da latência):
    ```sh
    aws configure
    ```

5. Configure e inicialize o Terraform:
    ```sh
    terraform init
    terraform apply
    ```

6. Construir e empurrar a imagem Docker:

    A imagem Docker foi necessária, pois as bibliotecas ultrapassaram o limite de memória do lambda da AWS.

    ```sh
    docker build -t my-lambda-repo .
    aws ecr get-login-password --region sa-east-1 | docker login --username AWS --password-stdin <seu-aws-account-id>.dkr.ecr.sa-east-1.amazonaws.com
    docker tag my-lambda-repo:latest <seu-aws-account-id>.dkr.ecr.sa-east-1.amazonaws.com/my-lambda-repo:latest
    docker push <seu-aws-account-id>.dkr.ecr.sa-east-1.amazonaws.com/my-lambda-repo:latest
    ```

7. Atualize o Terraform com a URI da imagem Docker:
    ```hcl
    resource "aws_lambda_function" "predict_function" {
      function_name = "predict_survival"
      package_type  = "Image"
      image_uri     = "<seu-aws-account-id>.dkr.ecr.sa-east-1.amazonaws.com/my-lambda-repo:latest"
      role          = aws_iam_role.lambda_exec_role.arn
    }
    ```

## Endpoints da API

### POST /sobreviventes
- **Descrição**: Cria uma nova previsão de sobrevivência
- **Request Body**:
    ```json
    {
        "Age": 29,
        "Fare": 100.0,
        "Pclass": 1,
        "Parch": 0,
        "SibSp": 1,
        "Sex_male": 0,
        "Embarked_Q": 1,
        "Embarked_S": 0
    }
    ```
- **Response**:
    ```json
    {
        "prediction": 1
    }
    ```

### GET /sobreviventes
- **Descrição**: Lista todas as previsões de sobrevivência
- **Response**:
    ```json
    [
        {
            "id": "1234",
            "Age": 29,
            "Fare": 100.0,
            "Pclass": 1,
            "Parch": 0,
            "SibSp": 1,
            "Sex_male": 0,
            "Embarked_Q": 0,
            "Embarked_S": 1,
            "prediction": 1
        },
        ...
    ]
    ```

### GET /sobreviventes/{id}
- **Descrição**: Obtém a previsão de sobrevivência para um passageiro específico
- **Parameters**:
    - `id` (string) - ID do passageiro
- **Response**:
    ```json
    {
        "id": "1234",
        "Age": 29,
        "Fare": 100.0,
        "Pclass":1,
        "Parch": 0,
        "SibSp": 1,
        "Sex_male": 0,
        "Embarked_Q": 0,
        "Embarked_S": 1,
        "prediction": 1
    }
    ```

### DELETE /sobreviventes/{id}
- **Descrição**: Deleta a previsão de sobrevivência para um passageiro específico
- **Parameters**:
    - `id` (string) - ID do passageiro
- **Response**:
    ```json
    {
        "message": "Previsão excluída com sucesso"
    }
    ```

## Visualizar Documentação OpenAPI

A documentação completa da API, escrita em OpenAPI 3.0, pode ser visualizada usando o [Swagger UI](https://github.com/swagger-api/swagger-ui).

Para ver a documentação localmente:

1. Clone o repositório Swagger UI:

2. Copie seu arquivo `openapi.yaml` para o diretório `dist` do Swagger UI.

3. Abra o arquivo `index.html` em seu navegador para visualizar a documentação.

## Agradecimentos

Obrigado ao Itaú pelo fornecimento dos dados de treino para a aplicação.

## Licença

Aberta.