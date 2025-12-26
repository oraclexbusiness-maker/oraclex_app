# OracleX App

A comprehensive business intelligence and automation platform designed to streamline workflows, enhance productivity, and provide actionable insights through advanced analytics and intelligent automation.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Setup Instructions](#setup-instructions)
- [Using the Automated Setup Script](#using-the-automated-setup-script)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

### Core Capabilities

- **Automated Setup Script**: One-command setup for rapid deployment and configuration
- **Business Intelligence Dashboard**: Real-time analytics and data visualization
- **Workflow Automation**: Streamlined business process automation
- **API Integration**: Seamless integration with third-party services
- **User Authentication**: Secure authentication and authorization system
- **Data Management**: Comprehensive data handling and storage
- **Reporting Engine**: Advanced reporting capabilities with customizable reports
- **Notification System**: Real-time alerts and notifications
- **Performance Monitoring**: Built-in monitoring and performance tracking
- **Scalable Architecture**: Designed to handle growing business needs

## Requirements

### System Requirements

- **OS**: Linux, macOS, or Windows (with WSL2)
- **Python**: 3.8 or higher
- **Node.js**: 14.0 or higher (for frontend components)
- **Database**: PostgreSQL 12+ or MySQL 8.0+
- **RAM**: Minimum 4GB (8GB recommended)
- **Disk Space**: Minimum 2GB free space
- **Internet Connection**: Required for initial setup and API integrations

### Software Dependencies

The application manages dependencies automatically through:
- `requirements.txt` - Python package dependencies
- `package.json` - Node.js package dependencies
- Database initialization scripts

## Quick Start

### For Impatient Users (Automated Setup)

```bash
# Clone the repository
git clone https://github.com/oraclexbusiness-maker/oraclex_app.git
cd oraclex_app

# Run the automated setup script
./setup.sh

# Start the application
python app.py
```

### For Manual Setup

See the [Setup Instructions](#setup-instructions) section below.

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/oraclexbusiness-maker/oraclex_app.git
cd oraclex_app
```

### Step 2: Create Virtual Environment (Python)

```bash
# On macOS/Linux
python3 -m venv venv
source venv/bin/activate

# On Windows
python -m venv venv
venv\Scripts\activate
```

### Step 3: Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Install Node.js Dependencies (if applicable)

```bash
npm install
# or if using yarn
yarn install
```

### Step 5: Configure Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` and update the following variables:

```env
# Application Settings
APP_NAME=OracleX
APP_ENV=development
DEBUG=True
SECRET_KEY=your-secret-key-here

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/oraclex_db
# or for MySQL: mysql://username:password@localhost:3306/oraclex_db

# API Keys (if required)
API_KEY=your-api-key-here
EXTERNAL_API_KEY=your-external-api-key

# Server Configuration
HOST=0.0.0.0
PORT=5000

# Email Configuration (optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/app.log
```

### Step 6: Initialize Database

```bash
# Create database
python manage.py db init
python manage.py db migrate
python manage.py db upgrade

# Or if using direct SQL scripts
psql -U postgres -d oraclex_db -f database/init.sql
```

### Step 7: Create Admin User (if applicable)

```bash
python manage.py create_admin --username admin --email admin@example.com --password admin_password
```

### Step 8: Start the Application

```bash
python app.py
```

The application should now be running at `http://localhost:5000`

## Using the Automated Setup Script

### Overview

The `setup.sh` script automates the entire setup process, making it easy for new developers and users to get started quickly.

### Prerequisites for Script

- Bash shell (Linux/macOS) or Git Bash (Windows)
- Internet connection
- Git installed and configured

### Running the Script

#### On macOS/Linux:

```bash
# Make script executable (first time only)
chmod +x setup.sh

# Run the script
./setup.sh
```

#### On Windows (using Git Bash or WSL2):

```bash
# Using Git Bash
bash setup.sh

# Or using WSL2
wsl ./setup.sh
```

### What the Script Does

1. **Environment Detection**: Detects your OS and sets up paths accordingly
2. **Dependency Verification**: Checks for required software (Python, Node.js, Git)
3. **Repository Setup**: Clones or updates the repository
4. **Virtual Environment**: Creates and activates Python virtual environment
5. **Dependency Installation**: Installs all Python and Node.js packages
6. **Database Setup**: Initializes and configures the database
7. **Environment Configuration**: Sets up `.env` file with sensible defaults
8. **Initial Data**: Loads initial data and creates admin user
9. **Health Check**: Verifies the installation is successful

### Script Options

```bash
# Run with specific options
./setup.sh --production          # Setup for production environment
./setup.sh --skip-db             # Skip database initialization
./setup.sh --skip-deps           # Skip dependency installation
./setup.sh --help                # Show available options
```

### Script Output

The script provides clear output and logging:

```
[INFO] Starting OracleX App Setup...
[INFO] Checking system requirements...
[✓] Python 3.9.0 found
[✓] Node.js 16.0.0 found
[✓] Git 2.30.0 found
[INFO] Installing Python dependencies...
[✓] Dependencies installed successfully
[INFO] Initializing database...
[✓] Database initialized
[INFO] Setup completed successfully!
[INFO] Start the application with: python app.py
```

### Troubleshooting Script Issues

If the script fails:

1. **Permission Denied**: `chmod +x setup.sh`
2. **Line Endings Error** (Windows): Convert line endings to UNIX format using `dos2unix setup.sh`
3. **Python Not Found**: Ensure Python 3.8+ is installed and in PATH
4. **Database Connection Failed**: Check database service is running and credentials in `.env`

## Project Structure

```
oraclex_app/
├── app.py                      # Main application entry point
├── setup.sh                    # Automated setup script
├── requirements.txt            # Python dependencies
├── package.json               # Node.js dependencies
├── .env.example               # Environment variable template
├── README.md                  # This file
├── config/
│   ├── __init__.py
│   ├── config.py              # Configuration settings
│   └── logging.py             # Logging configuration
├── src/
│   ├── __init__.py
│   ├── models/                # Database models
│   ├── routes/                # API routes and blueprints
│   ├── services/              # Business logic
│   ├── utils/                 # Utility functions
│   └── middleware/            # Middleware components
├── database/
│   ├── init.sql               # Database initialization script
│   └── migrations/            # Database migrations
├── static/                    # Frontend assets (CSS, JS, images)
├── templates/                 # HTML templates
├── tests/                     # Unit and integration tests
├── logs/                      # Application logs
└── docs/                      # Additional documentation
```

## Configuration

### Environment Variables

Key environment variables for customization:

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_ENV` | Application environment (development/production) | development |
| `DEBUG` | Enable debug mode | False |
| `DATABASE_URL` | Database connection string | sqlite:///app.db |
| `SECRET_KEY` | Application secret key | generated on startup |
| `HOST` | Server host address | 0.0.0.0 |
| `PORT` | Server port | 5000 |
| `LOG_LEVEL` | Logging level (DEBUG/INFO/WARNING/ERROR) | INFO |

### Database Configuration

Supported databases:
- **PostgreSQL** (recommended): `postgresql://user:pass@localhost/dbname`
- **MySQL**: `mysql://user:pass@localhost/dbname`
- **SQLite** (development): `sqlite:///app.db`

### Production Deployment

For production deployment:

```bash
# Run setup script in production mode
./setup.sh --production

# Update .env with production settings
APP_ENV=production
DEBUG=False
SECRET_KEY=strong-random-key-here
DATABASE_URL=postgresql://prod_user:prod_pass@prod_host/prod_db

# Start with production server
gunicorn app:app --workers 4 --bind 0.0.0.0:5000
```

## Usage

### Running the Application

```bash
# Development mode
python app.py

# Production mode with Gunicorn
gunicorn app:app --workers 4 --bind 0.0.0.0:5000

# With environment-specific config
APP_ENV=production python app.py
```

### Accessing the Application

- **Web Interface**: http://localhost:5000
- **API Documentation**: http://localhost:5000/api/docs
- **Admin Panel**: http://localhost:5000/admin

### Common Tasks

#### Create a New User

```bash
python manage.py create_user --username newuser --email user@example.com
```

#### Run Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src tests/

# Run specific test file
pytest tests/test_auth.py
```

#### Generate Database Migrations

```bash
# After modifying models
python manage.py db migrate -m "Description of changes"
python manage.py db upgrade
```

#### View Application Logs

```bash
# Real-time logs
tail -f logs/app.log

# Last 50 lines
tail -50 logs/app.log
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Python Version Error

**Error**: `Python 3.8 or higher is required`

**Solution**:
```bash
python3 --version
# If Python 3.8+ not available, install from python.org
```

#### 2. Database Connection Failed

**Error**: `could not connect to server: Connection refused`

**Solution**:
```bash
# Ensure database service is running
# For PostgreSQL:
brew services start postgresql  # macOS
sudo service postgresql start   # Linux

# Check database credentials in .env
```

#### 3. Port Already in Use

**Error**: `Address already in use`

**Solution**:
```bash
# Change port in .env
PORT=5001

# Or kill process using the port
lsof -ti:5000 | xargs kill -9  # macOS/Linux
```

#### 4. Module Not Found Error

**Error**: `ModuleNotFoundError: No module named 'flask'`

**Solution**:
```bash
# Ensure virtual environment is activated
source venv/bin/activate  # macOS/Linux
venv\Scripts\activate     # Windows

# Reinstall dependencies
pip install -r requirements.txt
```

#### 5. Permission Denied on setup.sh

**Error**: `Permission denied: ./setup.sh`

**Solution**:
```bash
chmod +x setup.sh
./setup.sh
```

### Getting Help

- Check the [documentation](docs/) folder for detailed guides
- Review [existing issues](https://github.com/oraclexbusiness-maker/oraclex_app/issues)
- Create a new issue with detailed error information
- Contact: support@oraclex.app

## Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/your-feature`
3. **Commit** your changes: `git commit -am 'Add new feature'`
4. **Push** to the branch: `git push origin feature/your-feature`
5. **Submit** a pull request

### Development Guidelines

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) for Python code
- Write unit tests for new features
- Update documentation as needed
- Ensure all tests pass: `pytest`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Support and Contact

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/oraclexbusiness-maker/oraclex_app/issues)
- **Email**: support@oraclex.app
- **Website**: https://oraclex.app

---

**Last Updated**: December 26, 2025

For the latest updates and changes, please refer to the [CHANGELOG](CHANGELOG.md) file.
