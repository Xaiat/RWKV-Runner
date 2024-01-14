# This RR.sh script is used to scan the model folder and load the model
# 本 RR.sh 脚本作用是用来扫描模型文件夹和载入模型
# The model folder path is /root/RWKV-Runner/models
# 模型文件目录路径
#!/bin/bash

# Start RWKV-Runner service script 
# 启动 RWKV-Runner 服务的脚本
echo "Starting RWKV-Runner service..."

# Check if port 8000 is already in use. If it is occupied, try to terminate the existing process and wait for 1 second
# 检查端口 8000 是否已被占用 如果被占用则尝试终止已有进程 并等待1秒
if lsof -i :8000; then
    echo "Port 8000 is already in use. Trying to terminate the existing process."
    fuser -k 8000/tcp
    sleep 1
fi

# Use source command to activate the environment in the script. This requires you to know the location of the Conda initialization script, replace the path below with your actual Conda initialization script path.
# 在脚本中使用 source 命令来激活环境。这需要您知道 Conda 初始化脚本的位置，替换下面的路径为您的实际 Conda 初始化脚本路径。
source /root/anaconda3/etc/profile.d/conda.sh

# Activate Conda environment
# 激活 Conda 环境
conda activate RWKV-Runner

# Run RWKV-Runner service
# 运行 RWKV-Runner 服务
python3 ./backend-python/main.py --host 0.0.0.0 --webui &
echo "RWKV-Runner is starting......"

# Wait for 1 second to make sure the service has started 
# 等待1秒确保服务已经启动
sleep 1

# List all model files
# 列出所有模型文件
echo "Available models:"
model_files=(/root/Models/*.pth)
for i in "${!model_files[@]}"; do
    echo "$((i+1))) ${model_files[$i]}"
done

# Let the user choose the model
# 让用户选择模型
echo "Please select a model by entering the number (e.g., 1 for the first model):"
read model_choice
model_choice=$((model_choice-1))

# Validate user input
# 校验用户输入
if [[ $model_choice -ge 0 && $model_choice -lt ${#model_files[@]} ]]; then
    selected_model=${model_files[$model_choice]}
    selected_model=${selected_model##*/} # 获取文件名

    # Execute curl command to set the model
    # 执行 curl 命令设置模型
    curl -X 'POST' \
      'http://127.0.0.1:8000/switch-model' \
      -H 'accept: application/json' \
      -H 'Content-Type: application/json' \
      -d "{
      \"customCuda\": false,
      \"deploy\": false,
      \"model\": \"/root/Models/$selected_model\",
      \"strategy\": \"cuda fp16\",
      \"tokenizer\": \"\"
    }"
else
    echo "Invalid selection. Exiting."
    exit 1
fi

# Show the service is started successfully
# 显示服务已经启动成功 
echo -e "RWKV-Runner started.\n\nhttp://192.168.1.15:8000 for LAN\n\nhttp://cgxcgx.com:54321 for WAN\n"
