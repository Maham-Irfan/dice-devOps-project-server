from flask import Flask,jsonify,request,Response,send_file
import os
from simple_file_checksum import get_checksum
from flask_cors import CORS
import base64

app = Flask(__name__)
CORS(app)

@app.route("/")
def home():
    return {"message":"This is a back end service used to create a file of 1kB of random data and sending it along with its checksum to the front end service"}

@app.route("/api")
def index():    
    
    directory_path = './serverdata'
    if not os.path.exists(directory_path):
        os.makedirs(directory_path)
    file_path = os.path.join(directory_path, 'my_file.txt')
    with open(file_path, 'wb') as file:
        file.write(os.urandom(1024))
        print('filecreated')
    checksum = get_checksum("./serverdata/my_file.txt", algorithm="MD5")
    print(checksum)
    with open(file_path, 'rb') as file:
        file_content = base64.b64encode(file.read()).decode('utf-8')
    response_data = {
        'file_content': file_content,
        'checksum': checksum
    }

    return jsonify(response_data)
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)