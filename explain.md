# explain.md — Project Reference Guide

这份文件按目录梳理 `minicloud` 项目的全部源文件、用途以及关键函数/接口，方便快速定位实现位置或确认改动影响范围。

## 1. 根目录与通用配置
- `.gitattributes` / `.gitignore`：Git 行为和忽略规则设置。
- `README.md` / `PROJECT_STATUS.md` / `HELP.md` / `����.md`：项目说明、进度、操作指引及需求记录。
- `pom.xml`：后端 Spring Boot + MyBatis-Plus + Security + MinIO 等依赖与构建配置。
- `mvnw`, `mvnw.cmd`, `.mvn/wrapper/*`：Maven Wrapper，保障一致构建环境。
- `Dockerfile` / `frontend/Dockerfile`：后端打包为可执行 Jar，前端构建静态资源镜像。
- `docker-compose.yml`：编排 MySQL、Redis、MinIO、后端、前端等容器服务。
- `start.sh`：本地一键编译 + `docker-compose` 启动脚本。
- `.vscode/settings.json`：推荐的工作区格式化配置。
- `tmp_fix_newlines.py`：批量修正换行符的小工具。
- `explain.md`：本文档。

> **说明**：`frontend/dist/*` 为前端构建产物（CSS/JS/HTML），部署时使用；开发无需修改。

## 2. 后端（`src/main/java/com/minicloud`）
### 2.1 启动与配置
- `CloudDiskApplication.java`：Spring Boot 入口，`main` 方法启动应用。
- `config/DefaultAdminInitializer.java`：`@EventListener` 初始化事件中创建默认管理员与基础配置。
- `config/JacksonConfig.java`：注册全局 `ObjectMapper` 自定义设置（时区、序列化策略）。
- `config/MinioConfig.java` / `config/properties/MinioProperties.java`：绑定 MinIO 连接属性，声明 `MinioClient` Bean。
- `config/MybatisPlusConfig.java`：配置分页插件、SQL 打印等 MyBatis-Plus 扩展。
- `config/PasswordConfig.java`：暴露 `PasswordEncoder` Bean。
- `config/RedisConfig.java`：配置 Redis 连接工厂与模板。
- `config/SecurityConfig.java`：Spring Security 安全链（JWT 过滤器、端点放行、异常处理）。

### 2.2 安全模块（`security/`）
- `JwtAuthenticationEntryPoint.java`：未认证访问时的处理。
- `JwtAuthenticationFilter.java`：从 Header 读取 Bearer Token，调用 `JwtTokenProvider` 校验并放入 SecurityContext。
- `JwtTokenProvider.java`：生成/解析 JWT，`generateToken`、`getUserIdFromToken`、`validateToken`。
- `UserPrincipal.java`：自定义 `UserDetails`，包含用户 ID、角色、空间信息等。

### 2.3 DTO（`dto/`）
请求/响应载体，常见字段校验：
- 认证：`LoginRequest`, `RegisterRequest`, `ChangePasswordRequest`, `ResetPasswordRequest`, `JwtAuthenticationResponse`。
- 用户/部门：`AdminUserCreateRequest`, `AdminUserUpdateRequest`, `AdminUserResponse`, `DepartmentCreateRequest`, `DepartmentUpdateRequest`, `DepartmentResponse`, `DepartmentTreeNode`。
- 文件/分享：`CreateDirectoryRequest`, `ShareCreateRequest`, `SharePermissionRequest`, `ShareInfoResponse`（组合分享+文件+分享人信息），`SpaceOverviewResponse`, `SpaceCleanupResponse`。
- 审批：`ApprovalCreateRequest`, `ApprovalActionRequest`。
- 系统配置：`SystemConfigRequest`, `SystemConfigResponse`。
- 通用响应：`ApiResponse<T>`（`success`、`data`、`message` 封装）。

### 2.4 实体（`entity/`）
MyBatis-Plus 映射数据库表：`User`, `Department`, `FileInfo`, `FileShare`, `FileApproval`, `SystemSetting`, `SystemLog`。包含字段、逻辑删除标记、自动填充策略等。

### 2.5 Mapper（`mapper/`）
- `UserMapper`, `DepartmentMapper`, `FileInfoMapper`, `FileShareMapper`, `FileApprovalMapper`, `SystemLogMapper`, `SystemSettingMapper`：继承 `BaseMapper<T>` 并通过注解/Xml (`resources/mapper/FileInfoMapper.xml`) 提供自定义查询（如 `findSharedToUser`, `searchFiles`, 空间统计语句等）。

### 2.6 Service 接口（`service/`）
- `UserService`: 用户注册/更新/权限校验/空间统计等抽象。
- `DepartmentService`: 部门树、管理者维护、空间统计。
- `FileService`: 文件 CRUD、上传下载、回收站、权限验证等。
- `FileShareService`: 分享创建、查询、权限校验、撤销与（新加的）`removeReceivedShares`。
- `FileApprovalService`: 审批流程接口。
- `MinioService`: 与对象存储交互（上传、下载、拷贝、预签名 URL）。
- `SystemSettingService`: 系统配置项读写。

### 2.7 Service 实现（`service/impl/`）
- `CustomUserDetailsService`: 实现 `loadUserByUsername` 供 Spring Security 认证使用。
- `UserServiceImpl`: 核心方法：`register`, `changePassword`, `resetPassword`, `updateUserInfo`, `updateUserStatus`, `updateUserSpaceSize`, `updateUsedSpaceSize`, `adminResetPassword`, `createUser`, `adminUpdateUser`, `deleteUser`, `checkUserPermission`, `listAllUsers`。
- `DepartmentServiceImpl`: `getDepartmentTree`, `refreshDepartmentManager`, `removeManagerAssignments`, `createDepartment`, `updateDepartment`, `deleteDepartment`, `updateDepartmentUsedSpace`, `isSubordinate`。
- `FileServiceImpl`: 负责文件全流程，关键方法：`uploadFile`, `uploadChunk`, `downloadFile`, `getPreviewUrl`, `createDirectory`, `deleteFile`, `permanentDeleteFile`, `restoreFile`, `renameFile`, `moveFile`, `copyFile`, `getFileList`, `searchFiles`, `getRecycledFiles`, `clearRecycleBin`, `checkFilePermission`, `getFilePath`, `calculateDirectorySize`, `deleteUserPersonalSpace`, `getSpaceOverview`, `cleanupSystemGarbage`, 以及辅助 `listBySpaceDirect` 等内部方法。
- `FileShareServiceImpl`: 分享逻辑与 DTO 构建：`createShare`, `updateSharePermissions`, `cancelShare`, `getUserShares`, `getSharedToUser`, `getSharedToDepartment`, `checkSharePermission`, `findEffectiveShare`, `getFileShareInfo`, `batchShare`, `checkShareExpired`, `cleanExpiredShares`, `removeSharesRelatedToUser`, **新加** `removeReceivedShares`，以及内部 `toShareInfoResponse`（组装分享+文件+分享人信息）。
- `FileApprovalServiceImpl`: `createApproval`, `listMyApplications`, `listPendingApprovals`, `listApprovalHistory`, `approve`, `reject`。
- `MinioServiceImpl`: `init`, `uploadFile`（Multipart & InputStream 版本), `downloadFile`, `deleteFile`, `getPresignedUrl`, `fileExists`, `getFileInfo`, `copyFile`, `generateUniqueFileName`。
- `SystemSettingServiceImpl`: `getValue`, `getLongValue`, `setValue`, `getSystemConfig`, `updateSystemConfig`。

### 2.8 Controller（`controller/`）
- `AuthController`: 认证端点 —— `authenticateUser`, `logout`, `registerUser`, `changePassword`, `resetPassword`。
- `UserController`: 个人中心 —— `getUserInfo`, `updateProfile`。
- `DepartmentController`: `getDepartmentTree`（给前端树形结构）。
- `AdminUserController`: 管理员用户接口 —— `listUsers`, `createUser`, `updateUser`, `deleteUser`, `updateStatus`, `updateSpace`, `resetPassword`。
- `AdminDepartmentController`: 部门管理 —— `listDepartments`, `createDepartment`, `updateDepartment`, `deleteDepartment`。
- `AdminSpaceController`: 空间统计/清理 —— `getSpaceOverview`, `cleanupSystemSpace`。
- `SystemConfigController`: `getSystemConfig`, `updateSystemConfig`。
- `FileController`: 文件相关 REST，包括 `uploadFile`, `uploadChunk`, `downloadByPath`/`downloadByAny`（GET/POST 兼容下载）, `getPreviewUrl`, `createDirectory`, `deleteFile`, `permanentDeleteFile`, `deleteFiles`（CSV/JSON/DELETE 三种批量方式）, `restoreFile`, `renameFile`, `moveFile`, `copyFile`, `listFiles`, `searchFiles`, 回收站系列 `getRecycledFiles` / `listRecycle` / `restoreFromRecycle` / `clearRecycleCompat` / `permanentDeleteCompat`, `getFilePath`。
- `FileShareController`: 分享模块 —— `createShare`, `updateShare`, `cancelShare`, `getMyShares`, `getReceivedShares`, **新增** `removeReceivedShares`, `getFileShareInfo`。
- `FileApprovalController`: 审批模块 —— `createApproval`, `listMyApplications`, `listPendingApprovals`, `listApprovalHistory`, `approve`, `reject`。

### 2.9 资源文件（`src/main/resources`）
- `application.properties`: 数据源、Redis、MinIO、JWT、CORS 等配置。
- `db/migration/V1__Initial_Schema.sql`: 创建所有基础表结构。
- `V2__Add_System_Settings.sql`: 系统配置表。
- `V3__Add_File_Indexes.sql`: 文件表索引。
- `mapper/FileInfoMapper.xml`: 自定义 SQL（复杂列表、空间统计等）。

### 2.10 测试
- `src/test/java/com/minicloud/CloudDiskApplicationTests.java`: 占位测试类，可用于 Spring 上下文加载验证。

## 3. 前端（`frontend/`）
### 3.1 入口与全局
- `src/main.ts`: 创建 Vue 应用、挂载 Pinia & Router。
- `src/App.vue`: 顶层布局（侧边栏 + 主内容），负责路由渲染。
- `vite.config.ts`: Vite 构建配置（路径别名 `/@`, 代理 `/api`）。
- `package.json`: 依赖（Vue3、Element Plus、Pinia、Axios 等）与脚本。

### 3.2 状态管理
- `src/stores/user.ts`: Pinia 用户仓库，暴露 `setToken`, `setUser`, `clearAuth`, `loginUser`, `logoutUser`, `fetchUserInfo` 以及计算属性 `isLoggedIn`, `isAdmin`, `isDepartmentAdmin`。

### 3.3 路由
- `src/router/index.ts`: 定义登录/注册/仪表盘/文件/审批/管理员等路由；`beforeEach` 守卫执行登录校验、管理员权限校验、Token 自动刷新。

### 3.4 API 模块（Axios 封装）
所有模块都通过 `api/request.ts` 创建的 Axios 实例（`baseURL: '/api'`, `Authorization` 自动注入）发送请求。
- `api/auth.ts`: `login`, `logout`, `register`, `changePassword`, `resetPassword`, `getUserInfo`。
- `api/files.ts`: `listFiles`, `createDirectory`, `uploadFile`, `deleteFiles`, `getRecycleList`, `restoreFile`, `clearRecycle`, `permanentDeleteFile`, `buildDownloadUrl`, `downloadFile`, `parseFilenameFromContentDisposition`。
- `api/shares.ts`: `listMyShares`, `listReceivedShares`, `getShareInfo`, `createShare`, `updateSharePermissions`, `cancelShare`, `removeReceivedShares`（DELETE `/shares/received`）。
- `api/approvals.ts`: `createApproval`, `listMyApplications`, `listPendingApprovals`, `listApprovalHistory`, `approve`, `reject`。
- `api/admin.ts`: 管理端操作（`listUsers`, `createUser`, `updateUser`, `deleteUser`, `updateUserStatus`, `updateUserSpace`, `resetUserPassword`, `fetchDepartments`, `createDepartment`, `updateDepartment`, `deleteDepartment`, `getSystemConfig`, `updateSystemConfig`, `getSpaceOverview`, `cleanupSystemSpace`）。
- `api/user.ts`: `updateProfile`。

### 3.5 类型定义（`types/`）
- `auth.ts`: `LoginRequest`, `UserInfo`, `ApiResponse<T>` 等前后端通用类型。
- `file.ts`: `FileInfo` 结构、共享空间属性。
- `share.ts`: 更新后的 `ShareInfo`, `ReceivedShareItem`, `ShareCreatePayload`, `SharePermissionPayload`。
- `approval.ts`: 审批请求/响应结构。
- `user.ts`: 管理端用户、部门、系统配置、空间统计等类型。

### 3.6 组件（`components/`）
- `FileExplorer.vue`: 通用文件管理组件，核心方法：
  - `refresh`, `callList`: 拉取文件列表。
  - `callCreateDir`, `onCreateDir`: 新建目录对话流程。
  - `callUpload`, `uploadRequest`: 处理 FormData 上传（兼容 `file`/`multipartFile` 字段）。
  - `enterDir`, `goUp`, `goRoot`, `jumpToCrumb`: 面包屑导航。
  - `callBatchDelete`, `onDeleteSelected`: 批量删除。
  - `onDownload`: 走 `/api/files/download/{id}` 获取 Blob 保存。
  - `onShareOk`: 分享成功后刷新。
  - 维护状态 `files`, `selection`, `crumbs`, `loading`, `uploading` 等。
- `ShareDialog.vue`: 分享弹窗，方法：`onOk`（提交 `createShare`/`updateSharePermissions`）与 `onClose`，组合 Form（分享类型、目标、权限、有效期）。
- `SharedSpaceExplorer.vue`: 分享视图，方法：`switchTab`, `reload`, `toggleAll`, `toggleOne`, `selectedRows`, `onRemove`（调用 `removeReceivedShares` 或 `cancelShare`）, `onShare`, `onShareOk`, `onDownload`。
- `RecycleExplorer.vue`: 回收站组件，方法：`loadRecycleList`, `onRestore`, `onDelete`, `onClear`, `refresh`。

### 3.7 页面（`views/`）
- `Dashboard.vue`: 包装布局 + 子路由容器，加载侧边导航。
- `Login.vue` / `Register.vue`: 表单提交调用 `api/auth` 模块。
- `Profile.vue`: 展示 & 更新个人资料；调用 `api/user.updateProfile`。
- `views/files/*.vue`：四种空间 + 回收站页面，均引入 `FileExplorer` 或 `RecycleExplorer`，通过 `spaceType`/`spaceId` 传参。
- `views/approvals/ApprovalCenter.vue`: 四个审批列表页签（申请、待办、历史），调用 `api/approvals`。
- `views/admin/AdminPanel.vue`: 汇总管理员功能，分区块调用 `api/admin`（用户列表、部门树、系统配置、空间概览/清理）。

### 3.8 工具
- `utils/coerce.ts`: 数值/布尔类型安全转换工具（`coerceNumber`, `coerceNullableNumber`, `coerceBoolean`, `coerceOptionalBoolean`）。

### 3.9 入口 HTML & 服务器配置
- `frontend/index.html`: Vite 模板。
- `frontend/nginx.conf`: 生产环境 Nginx 反向代理 `/api` -> 后端。

## 4. 数据库迁移（`src/main/resources/db/migration`）
- `V1__Initial_Schema.sql`: 创建 `sys_user`, `sys_department`, `file_info`, `file_share`, `file_approval`, `system_setting`, `system_log` 等表及索引。
- `V2__Add_System_Settings.sql`: 追加系统配置默认值。
- `V3__Add_File_Indexes.sql`: 优化文件查询性能。

## 5. 编译产物
- `frontend/dist/**/*`: 打包后的 HTML/CSS/JS。
- `target/`（如存在）：Maven 构建输出。

---

### 快速索引示例
- **文件下载链路**：`frontend/src/components/FileExplorer.vue => api/files.ts@onDownload => FileController.downloadByPath/downlaodByAny => FileServiceImpl.downloadFile => MinioServiceImpl.downloadFile`。
- **共享空间删除**：`SharedSpaceExplorer.vue@onRemove => api/shares.ts.removeReceivedShares => FileShareController.removeReceivedShares => FileShareServiceImpl.removeReceivedShares`。
- **审批通过**：`views/approvals/ApprovalCenter.vue@approve => api/approvals.ts.approve => FileApprovalController.approve => FileApprovalServiceImpl.approve`。

维护本文件时可按上述结构继续补充/更新，确保后续同事可直接查阅了解功能位置。
