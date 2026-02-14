# OKR Tracker 架构文档

## 项目概述

OKR Tracker 是一个基于 SwiftUI 构建的原生 iOS 应用，旨在通过科学的 OKR (Objectives and Key Results) 方法论帮助个人和团队高效管理目标。应用采用 MVVM 架构，支持中英文双语，包含目标管理、进度追踪、热力图可视化等功能。

## 技术栈

- **语言**: Swift 5
- **UI 框架**: SwiftUI
- **数据可视化**: Swift Charts
- **架构模式**: MVVM (Model-View-ViewModel)
- **本地存储**: JSON Persistence
- **兼容性**: iOS 16.0+

## 项目结构

```
OKRTracker/
├── Models/
│   └── OKR.swift              # 核心数据模型 (OKR, KeyResult, KRTask, ActivityLog)
├── ViewModels/
│   └── OKRStore.swift         # 数据管理和持久化
├── Views/
│   ├── Components/
│   │   └── ConfettiView.swift # 庆祝动画组件
│   ├── AddOKRView.swift       # 添加目标视图
│   ├── ContentView.swift      # 主视图 (TabView)
│   ├── DailyTasksView.swift   # 每日任务视图
│   ├── DashboardView.swift    # 仪表盘视图
│   ├── GoalListView.swift     # 目标列表视图
│   ├── OKRDetailView.swift    # 目标详情视图
│   └── SettingsView.swift     # 设置视图
├── Utilities/
│   ├── HapticManager.swift    # 触觉反馈管理
│   └── LocalizationManager.swift # 本地化管理
└── OKRTrackerApp.swift        # 应用入口点
```

## 数据模型设计

### OKR (目标与关键成果)
- `id`: 唯一标识符
- `title`: 目标标题
- `description`: 目标描述
- `keyResults`: 关键结果数组
- `startDate`/`dueDate`: 起止日期
- `isCompleted`/`isArchived`: 完成和归档状态
- `health`: 健康度 (自动计算)
- `progress`: 进度 (加权计算)

### KeyResult (关键结果)
- `type`: 类型 (数值/百分比/货币/布尔)
- `currentValue`/`targetValue`: 当前值/目标值
- `unit`: 单位
- `weight`: 权重
- `logs`: 活动日志
- `tasks`: 关联任务

### KRTask (关键结果任务)
- `recurrence`: 重复模式 (无/每日/每周/工作日)
- `weight`: 对关键结果的贡献值
- `completedDates`: 完成日期历史

### 健康度计算逻辑

健康度基于时间进度与目标进度的对比自动计算：

1. **已完成**: `progress >= 1.0`
2. **滞后**: 时间进度 > 80% 且 目标进度 < 50%
3. **风险**: 时间进度 > 50% 且 目标进度 < 70%
4. **正常**: 其他情况

## 视图模型设计

### OKRStore
- `@Published var okrs`: 可观察的目标数组
- **数据持久化**: 自动保存到 `okrs.json`
- **错误处理**: 优雅处理加载失败
- **自动归档**: 进度完成的目标自动归档

### 关键功能
1. **添加/删除目标**
2. **更新关键结果进度**
3. **自动记录活动日志**
4. **样本数据生成**

## 视图层设计

### 主要视图
1. **仪表盘 (DashboardView)**
   - 总体进度图表
   - 活跃热力图 (GitHub 风格)
   - 统计卡片

2. **目标列表 (GoalListView)**
   - 活动/归档目标切换
   - 目标卡片展示
   - 删除确认

3. **每日任务 (DailyTasksView)**
   - 按日期筛选任务
   - 任务完成切换
   - 自动更新关联的关键结果进度

4. **目标详情 (OKRDetailView)**
   - 进度图表
   - 关键结果管理
   - 进度更新和历史记录

## 本地化系统

### LocalizationManager
- 支持中英文双语
- 系统语言自动检测
- UserDefaults 持久化选择
- 字符串扩展简化调用 (`"key".localized`)

### 翻译键管理
- 按视图模块组织
- 覆盖所有用户界面文本
- 支持动态内容插值

## 数据持久化

### JSON 存储策略
- 文件位置: `Documents/okrs.json`
- 编码配置: ISO8601 日期格式，美化输出
- 错误处理: 加载失败时初始化为空数组
- 自动保存: `okrs` 数组变化时自动触发

### 数据模型兼容性
所有模型遵循 `Codable` 协议，确保向前/向后兼容性。

## 触觉反馈

### HapticManager
- 通知反馈 (成功/失败/警告)
- 撞击反馈 (轻/中/重)
- 选择反馈 (滚轮滑动感)
- 单例模式全局访问

## 重构与优化

### 已修复的问题
1. **健康度计算逻辑**
   - 原逻辑阈值不合理
   - 新逻辑更符合实际项目管理

2. **布尔类型处理**
   - 进度计算特殊处理 (0 或 1)
   - 热力图强度计算适配

3. **任务完成状态**
   - `KRTask.isCompleted` 逻辑错误
   - 现在基于 `completedDates` 正确计算

4. **数组遍历安全**
   - 使用 `indices` 替代 `0..<count`
   - 避免遍历时修改问题

5. **错误处理增强**
   - JSON 解码/编码错误捕获
   - 优雅的失败处理

6. **热力图计算优化**
   - 布尔类型特殊处理
   - 阈值分布调整

### 代码质量改进
1. **类型安全**: 枚举替代魔法字符串
2. **错误处理**: 全面的 try-catch 包装
3. **性能优化**: 避免不必要的计算
4. **可维护性**: 清晰的注释和结构

## 性能考虑

### 内存管理
- `@Published` 属性包装器实现响应式更新
- 懒加载大数据集
- 适当的生命周期管理

### 计算效率
- 进度计算缓存优化
- 热力图数据预计算
- 图表渲染性能优化

## 测试策略建议

### 单元测试
1. **模型测试**: OKR 健康度计算、进度计算
2. **视图模型测试**: OKRStore 数据操作
3. **工具类测试**: LocalizationManager, HapticManager

### UI 测试
1. **核心用户流程**: 创建目标、更新进度、完成任务
2. **边缘情况**: 空状态、错误处理、国际化

### 集成测试
1. **数据持久化**: 保存/加载完整性
2. **交互流程**: 端到端用户场景

## 扩展建议

### 功能扩展
1. **数据同步**: iCloud 或自定义后端
2. **团队协作**: 多用户支持
3. **高级分析**: 预测性洞察
4. **导出功能**: PDF/CSV 报告

### 技术改进
1. **状态管理**: 引入更专业的状态管理库
2. **依赖注入**: 提高可测试性
3. **模块化**: 功能模块分离
4. **性能监控**: 集成性能分析工具

## 部署要求

### 开发环境
- Xcode 15.0+
- iOS 16.0+ SDK
- Swift 5.9+

### 生产环境
- iOS 16.0+ 设备
- 足够的存储空间用于数据持久化
- 推荐 iPhone 14 Pro 及以上以获得最佳体验

## 维护指南

### 代码规范
- 遵循 Swift API 设计指南
- 使用 SwiftLint 进行代码检查
- 定期更新依赖和工具链

### 版本管理
- 语义化版本控制
- 详细的变更日志
- 向后兼容性保证

### 问题跟踪
- GitHub Issues 用于 bug 报告
- Pull Request 模板确保代码质量
- 定期代码审查

---

*本文档最后更新: 2026-02-14*
*对应版本: OKR Tracker v1.0*