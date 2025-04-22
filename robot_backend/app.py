from flask import Flask, request, jsonify

app = Flask(__name__)

# 模拟数据存储
data_store = {"welcome": "Hello, World!"}

@app.route('/api/data', methods=['GET'])
def get_data():
    """获取所有数据"""
    return jsonify(data_store)

@app.route('/api/freeze', methods=['GET'])
def freeze():
    """获取所有数据"""
    return jsonify("freeze")

@app.route('/api/follow', methods=['GET'])
def follow():
    """获取所有数据"""
    return jsonify("follow")

@app.route('/api/play', methods=['GET'])
def play():
    """获取所有数据"""
    return jsonify("play")

@app.route('/api/data', methods=['POST'])
def create_data():
    """创建新数据"""
    new_data = request.json
    if not new_data or 'id' not in new_data:
        return jsonify({'error': '数据格式错误'}), 400
    
    data_id = new_data['id']
    if data_id in data_store:
        return jsonify({'error': 'ID已存在'}), 400
    
    data_store[data_id] = new_data
    return jsonify({'message': '数据创建成功', 'data': new_data}), 201

@app.route('/api/data/<data_id>', methods=['PUT'])
def update_data(data_id):
    """更新指定ID的数据"""
    if data_id not in data_store:
        return jsonify({'error': '数据不存在'}), 404
    
    update_data = request.json
    if not update_data:
        return jsonify({'error': '数据格式错误'}), 400
    
    data_store[data_id].update(update_data)
    return jsonify({'message': '数据更新成功', 'data': data_store[data_id]})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000) 