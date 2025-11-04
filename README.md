# Enterprise Mini Cloud Disk

An enterprise-oriented file management platform that provides fine-grained authorization, multi-space collaboration, and approval workflows.

## Tech Stack

### Backend
- **Java 17** with **Spring Boot 2.7.18**
- **Spring Security + JWT** for authentication and authorization
- **MyBatis-Plus** for ORM
- **MySQL 8.0** as the relational database
- **Redis** for caching and session support
- **MinIO** for object storage

### Frontend
- **Vue 3** with **TypeScript**
- **Element Plus** component library
- **Pinia** for state management
- **Vite** build tool

### Deployment
- **Docker & Docker Compose** for container orchestration
- **Nginx** as reverse proxy and static asset server

## Features

### End Users
- Account registration, login, password change and recovery via security questions
- Profile management (name, phone, email, etc.)
- Personal/department/company/guest space browsing with permission-aware actions
- File upload, download, preview, search, recycle bin, and share capabilities
- Directory sharing with per-recipient permissions (download/upload/modify/view)
- Submission, tracking, and approval/rejection of file approval requests (`/api/approvals` REST endpoints)

### Administrators
- Bulk user import, activation/freeze, quota allocation, password reset
- Department management, merging, and administrator assignment
- Access to system logs, file type restrictions, backup/restore, storage analytics

## Project Structure

```
enterprise-cloud-disk/
├── src/main/java/com/minicloud/
│  ├── config/        # Spring and infrastructure configuration
│  ├── controller/    # REST controllers
│  ├── dto/           # Request/response models
│  ├── entity/        # MyBatis-Plus entities
│  ├── mapper/        # Mapper interfaces
│  ├── security/      # Security components
│  └── service/       # Business services and implementations
├── src/main/resources/
│  ├── db/migration/  # Flyway migration scripts
│  └── application.properties
├── frontend/         # Vue 3 client application
├── docker-compose.yml
├── Dockerfile
└── README.md
```

## Getting Started

### Prerequisites
- Docker & Docker Compose
- JDK 17+
- Node.js 18+

### Run with Docker (recommended)
```bash
docker-compose up -d
```

### Local Development
```bash
# Start MySQL, Redis, MinIO
docker-compose up -d mysql redis minio

# Backend
./mvnw spring-boot:run

# Frontend
cd frontend
npm install
npm run dev
```

## Contributing

1. Fork the repository  
2. Create a feature branch  
3. Commit your changes  
4. Open a pull request  

## License

Distributed under the MIT License. See `LICENSE` for details.
