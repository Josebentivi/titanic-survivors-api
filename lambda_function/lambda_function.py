import json
import boto3
from decimal import Decimal
import pickle
import random
from sklearn.ensemble import RandomForestClassifier
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('SurvivalPredictions')

# Função personalizada para converter objetos Decimal para float
def decimal_default(obj):
    if isinstance(obj, Decimal):
        return float(obj)
    raise TypeError

def handle_post(event):
    print("POST /sobreviventes called")
    print("Event body: ", event['body'])

    # Parseando o corpo da requisição
    body = json.loads(event['body'])
    
    # Extrair os parâmetros
    age = Decimal(body.get('Age'))
    fare = Decimal(body.get('Fare'))
    pclass = int(body.get('Pclass'))
    parch = int(body.get('Parch'))
    sibsp = int(body.get('SibSp'))
    sex_male = int(body.get('Sex_male'))
    embarked_q = int(body.get('Embarked_Q'))
    embarked_s = int(body.get('Embarked_S'))

    print(f"Age: {age}, Fare: {fare}, Pclass: {pclass}, Parch: {parch}, SibSp: {sibsp}, Sex_male: {sex_male}, Embarked_Q: {embarked_q}, Embarked_S: {embarked_s}")
    
    # Verificar se todos os campos necessários foram fornecidos
    if None in [age, fare, pclass, parch, sibsp, sex_male, embarked_q, embarked_s]:
        return {
            'statusCode': 400,
            'body': json.dumps('Parâmetros ausentes. Certifique-se de que todos os campos foram fornecidos.')
        }
    
    # Carregar o modelo pré-treinado
    model_path = f'./model.pkl'
    model = pickle.load(open(model_path, 'rb'))

    # Simulação de predição
    prediction = int(model.predict([[age, fare, pclass, parch, sibsp, sex_male, embarked_q, embarked_s]]))
    
    # Gerar um ID único para o passageiro
    passenger_id = body.get('PassengerId', str(random.randint(10000, 99999)))  # Você pode implementar uma lógica melhor para gerar IDs
    
    # Salvar a predição no DynamoDB
    try:
        table.put_item(
            Item={
                'PassengerId': passenger_id,
                'SurvivalProbability': prediction,
                'Age': age,
                'Fare': fare,
                'Pclass': pclass,
                'Parch': parch,
                'SibSp': sibsp,
                'Sex_male': sex_male,
                'Embarked_Q': embarked_q,
                'Embarked_S': embarked_s
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps({
                'PassengerId': passenger_id,
                'SurvivalProbability': prediction
            })
        }
    except Exception as e:
        print(f"Erro ao salvar no DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erro interno do servidor: {e}")
        }

def handle_get(event):
    print("GET /sobreviventes called")
    print("Event: ", event)
    
    # Extrair o ID do caminho, se existir
    path_parameters = event.get('pathParameters')
    if path_parameters and 'id' in path_parameters:
        passenger_id = path_parameters['id']
        
        # Buscar dados no DynamoDB
        response = table.get_item(Key={'PassengerId': passenger_id})
        item = response.get('Item')
        
        if not item:
            return {
                'statusCode': 404,
                'body': json.dumps('Passageiro não encontrado.')
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps(item, default=decimal_default)
        }
    
    # Se não há ID no caminho, listar todos os passageiros
    scan_response = table.scan()
    items = scan_response.get('Items', [])
    
     # Converter Decimal para float
    for item in items:
        item['SurvivalProbability'] = float(item['SurvivalProbability'])
        
    return {
        'statusCode': 200,
        'body': json.dumps(items, default=decimal_default)
    }

def handle_delete(event):
    print("DELETE /sobreviventes/{id} called")
    print("Event: ", event)
    
    # Extrair o ID do caminho
    path_parameters = event.get('pathParameters')
    if not path_parameters or 'id' not in path_parameters:
        return {
            'statusCode': 400,
            'body': json.dumps('ID do passageiro não fornecido.')
        }
    
    passenger_id = path_parameters['id']
    
    # Deletar item no DynamoDB
    try:
        response = table.delete_item(Key={'PassengerId': passenger_id})
        return {
            'statusCode': 200,
            'body': json.dumps(f'Passageiro com ID {passenger_id} deletado.')
        }
    except Exception as e:
        print(f"Erro ao deletar no DynamoDB: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Erro interno do servidor: {e}")
        }

def lambda_handler(event, context):
    print("Lambda function invoked")
    http_method = event.get('httpMethod')
    resource_path = event.get('resource')
    
    if http_method == 'POST' and resource_path == '/sobreviventes':
        return handle_post(event)
    elif http_method == 'GET' and resource_path == '/sobreviventes':
        return handle_get(event)
    elif http_method == 'GET' and resource_path == '/sobreviventes/{id}':
        return handle_get(event)
    elif http_method == 'DELETE' and resource_path == '/sobreviventes/{id}':
        return handle_delete(event)
    else:
        return {
            'statusCode': 405,
            'body': json.dumps(f'Método não permitido para o recurso {resource_path}.')
        }
