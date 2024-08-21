# Use a base image for AWS Lambda Python
FROM public.ecr.aws/lambda/python:3.12

# Install the required dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the function code
COPY /* .

# Command to run the Lambda function
CMD ["lambda_function.lambda_handler"]