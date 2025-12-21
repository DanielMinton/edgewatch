# Edgewatch

A Ruby on Rails application for monitoring and analytics.

## Tech Stack

### Languages
- **Ruby** (57 files) - Backend application logic, models, controllers
- **JavaScript** (6 files) - Frontend interactivity and asset pipeline
- **HTML** (5 files) - View templates (ERB)
- **CSS** (3 files) - Stylesheets and UI design
- **YAML** (13 files) - Configuration files (database, routes, locales)

### Framework & Infrastructure
- **Ruby on Rails** - Full-stack MVC web framework
- **Docker** - Containerization for consistent deployment
- **Bundler** - Ruby gem dependency management

## Getting Started

### Prerequisites
- Ruby (version specified in `.ruby-version`)
- Bundler (`gem install bundler`)
- Database (PostgreSQL or MySQL)

### Installation

```bash
# Install dependencies
bundle install

# Set up database
rails db:create
rails db:migrate

# Start the server
rails server
```

Visit `http://localhost:3000` to view the application.

## Development

```bash
# Run tests
rails test

# Open Rails console
rails console

# View routes
rails routes
```

## Deployment

This application is containerized with Docker for easy deployment.

```bash
docker build -t edgewatch .
docker run -p 3000:3000 edgewatch
```
