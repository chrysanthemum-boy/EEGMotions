# Flask REST API 示例

这是一个基本的Flask REST API示例，实现了GET、POST和UPDATE功能。

## 安装

1. 创建虚拟环境（推荐）：
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
.\venv\Scripts\activate  # Windows
```

2. 安装依赖：
```bash
pip install -r requirements.txt
```

## 运行

```bash
python app.py
```

服务器将在 http://localhost:5000 启动。

## API 端点

### 获取所有数据
- **GET** `/api/data`
- 返回所有存储的数据

### 创建新数据
- **POST** `/api/data`
- 请求体示例：
```json
{
    "id": "1",
    "name": "示例数据",
    "value": "123"
}
```

### 更新数据
- **PUT** `/api/data/<data_id>`
- 请求体示例：
```json
{
    "name": "更新后的数据",
    "value": "456"
}
```

## 注意事项

- 数据存储在内存中，重启服务器后数据会丢失
- 所有请求和响应都使用JSON格式 