--[[
神经网络模块完整示例 - 训练、保存、加载、预测

本示例展示:
1. 创建并训练神经网络
2. 保存训练好的模型
3. 从文件加载模型
4. 使用加载的模型进行预测
5. 获取和设置权重
--]]

local network = require("network")

print("=" .. string.rep("=", 60))
print("神经网络模块完整示例 - 保存与加载功能")
print("=" .. string.rep("=", 60))

-- ============================================================
-- 第一部分: 创建并训练神经网络
-- ============================================================
print("\n【第一部分】创建并训练神经网络")
print("-" .. string.rep("-", 40))

local net = network.new({8, 8, 1}, 2)
print("创建网络: 2输入 -> 8 -> 8 -> 1输出")
net:setLearningRate(0.1)
print("设置学习率: 0.1")

local data = {
    {input = {0, 0}, target = {0}},
    {input = {0, 1}, target = {1}},
    {input = {1, 0}, target = {1}},
    {input = {1, 1}, target = {2}}
}
print("训练数据: 0+0=0, 0+1=1, 1+0=1, 1+1=2")

print("\n开始训练 (10000轮)...")
local loss = net:train(data, 10000)
print("训练完成! 最终损失: " .. loss)

print("\n训练前测试:")
local test_cases = {{0, 0}, {0, 1}, {1, 0}, {1, 1}}
for _, tc in ipairs(test_cases) do
    local result = net:predict(tc)
    print("  " .. tc[1] .. " + " .. tc[2] .. " = " .. string.format("%.4f", result[1]))
end

-- ============================================================
-- 第二部分: 保存网络到文件
-- ============================================================
print("\n【第二部分】保存网络到文件")
print("-" .. string.rep("-", 40))

local model_path = "/sdcard/addition_network.bin"

local save_ok = net:save(model_path)
if save_ok then
    print("✓ 网络保存成功: " .. model_path)
    
    local info = net:info()
    print("  - 输入大小: " .. info.input_size)
    print("  - 输出大小: " .. info.output_size)
    print("  - 层数: " .. info.layer_count)
    print("  - 训练轮数: " .. info.epoch)
    print("  - 最终损失: " .. string.format("%.6f", info.last_loss))
else
    print("✗ 网络保存失败!")
    os.exit(1)
end

-- ============================================================
-- 第三部分: 从文件加载网络
-- ============================================================
print("\n【第三部分】从文件加载网络")
print("-" .. string.rep("-", 40))

local loaded_net = network.load(model_path)
if loaded_net then
    print("✓ 网络加载成功!")
    
    local info = loaded_net:info()
    print("  - 输入大小: " .. info.input_size)
    print("  - 输出大小: " .. info.output_size)
    print("  - 层数: " .. info.layer_count)
    print("  - 训练轮数: " .. info.epoch)
    print("  - 最终损失: " .. string.format("%.6f", info.last_loss))
else
    print("✗ 网络加载失败!")
    os.exit(1)
end

-- ============================================================
-- 第四部分: 使用加载的网络进行预测
-- ============================================================
print("\n【第四部分】使用加载的网络进行预测")
print("-" .. string.rep("-", 40))

print("使用加载的网络进行预测:")
for _, tc in ipairs(test_cases) do
    local result = loaded_net:predict(tc)
    local expected = tc[1] + tc[2]
    local error = math.abs(result[1] - expected)
    print("  " .. tc[1] .. " + " .. tc[2] .. " = " 
          .. string.format("%.4f", result[1]) 
          .. " (误差: " .. string.format("%.6f", error) .. ")")
end

-- ============================================================
-- 第五部分: 获取和设置权重
-- ============================================================
print("\n【第五部分】获取和设置权重")
print("-" .. string.rep("-", 40))

print("获取网络权重...")
local weights = net:getWeights()
print("✓ 权重获取成功!")
print("  层数: " .. #weights)

for i, layer in ipairs(weights) do
    print("  第" .. i .. "层:")
    print("    - 输入大小: " .. layer.input_size)
    print("    - 输出大小: " .. layer.output_size)
    print("    - 激活函数: " .. layer.activation)
    print("    - 权重矩阵: " .. layer.output_size .. "x" .. layer.input_size)
    print("    - 偏置向量: " .. layer.output_size .. "个")
    
    -- 显示部分权重
    if i == 1 then
        print("    - 权重示例[1][1]: " .. string.format("%.6f", layer.weights[1][1]))
    end
end

print("\n复制网络并设置权重...")
local net_copy = net:clone()
local set_ok = net_copy:setWeights(weights)
if set_ok then
    print("✓ 权重设置成功!")
    
    local result1 = net:predict({1, 1})
    local result2 = net_copy:predict({1, 1})
    print("  原始网络预测 1+1: " .. string.format("%.6f", result1[1]))
    print("  复制网络预测 1+1: " .. string.format("%.6f", result2[1]))
else
    print("✗ 权重设置失败!")
end

-- ============================================================
-- 第六部分: 完整工作流程演示
-- ============================================================
print("\n【第六部分】完整工作流程演示")
print("-" .. string.rep("-", 40))
print("模拟实际应用场景:")
print("  1. 训练阶段: 在PC上训练模型并保存")
print("  2. 部署阶段: 在Android上加载模型进行预测")

local demo_path = "/sdcard/demo_network.bin"

print("\n步骤1: 模拟在PC上训练...")
local demo_net = network.new({4, 4, 1}, 2)
demo_net:setLearningRate(0.5)

local demo_data = {
    {input = {0, 0}, target = {0}},
    {input = {0, 1}, target = {1}},
    {input = {1, 0}, target = {1}},
    {input = {1, 1}, target = {2}}
}
demo_net:train(demo_data, 5000)
print("  训练完成, 损失: " .. string.format("%.6f", demo_net:lastLoss()))

print("\n步骤2: 保存模型...")
demo_net:save(demo_path)
print("  模型已保存到: " .. demo_path)

print("\n步骤3: 模拟在Android上加载模型...")
local android_net = network.load(demo_path)
print("  模型加载成功!")

print("\n步骤4: 使用模型进行预测...")
local inputs = {{0, 0}, {0, 1}, {1, 0}, {1, 1}}
for _, inp in ipairs(inputs) do
    local result = android_net:predict(inp)
    local expected = inp[1] + inp[2]
    local correct = math.abs(result[1] - expected) < 0.1
    local status = correct and "✓" or "✗"
    print("  " .. status .. " " .. inp[1] .. " + " .. inp[2] .. " = " 
          .. string.format("%.2f", result[1]) .. " (期望: " .. expected .. ")")
end

-- ============================================================
-- 总结
-- ============================================================
print("\n" .. "=" .. string.rep("=", 60))
print("示例完成!")
print("=" .. string.rep("=", 60))
print("\n关键API总结:")
print("  - network.new(architecture, input_size)  创建网络")
print("  - net:train(data, epochs)                训练网络")
print("  - net:save(filename)                     保存网络")
print("  - network.load(filename)                 加载网络")
print("  - net:predict(input)                     进行预测")
print("  - net:getWeights()                       获取权重")
print("  - net:setWeights(weights)                设置权重")
print("  - net:info()                             获取信息")
print("  - network.help()                         查看帮助")
print("\n文件路径示例:")
print("  - /sdcard/model.bin     (外部存储)")
print("  - /data/data/xxx/files/model.bin (应用私有目录)")
print("  - assets/model.bin      (APK资源)")
