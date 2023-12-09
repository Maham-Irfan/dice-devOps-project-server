FROM python:3.11.7-slim-bullseye
COPY . .
RUN pip install -r requirements.txt
EXPOSE 8080
ENTRYPOINT ["python","app.py"]