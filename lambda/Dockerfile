FROM public.ecr.aws/lambda/python:3.11

# aws lambda practice
WORKDIR /var/task


COPY requirements.txt .


RUN pip install -r requirements.txt


COPY spotify_data.py .


CMD ["spotify_data.lambda_handler"]