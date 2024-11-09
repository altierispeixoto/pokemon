# Default command: List available commands
default:
    @just --list

# Define Docker Compose file and project name
compose_file := "docker-compose.yml"
project_name := "pokemon"

# Build Docker images
build:
    docker compose -f {{compose_file}} -p {{project_name}} build

# Start services
up *args:
    docker compose -f {{compose_file}} -p {{project_name}} up -d {{args}}

# Stop services
down:
    docker compose -f {{compose_file}} -p {{project_name}} down

# View logs
logs *args:
    docker compose -f {{compose_file}} -p {{project_name}} logs -f {{args}}

# List running containers
ps:
    docker compose -f {{compose_file}} -p {{project_name}} ps

# Execute a command in a running container
exec service command *args:
    docker compose -f {{compose_file}} -p {{project_name}} exec {{service}} {{command}} {{args}}

# Pull latest images
pull:
    docker compose -f {{compose_file}} -p {{project_name}} pull

# Restart services
restart *services:
    docker compose -f {{compose_file}} -p {{project_name}} restart {{services}}

# Run a one-off command
run service command *args:
    docker compose -f {{compose_file}} -p {{project_name}} run --rm {{service}} {{command}} {{args}}

# View resource usage
top:
    docker compose -f {{compose_file}} -p {{project_name}} top

# Clean up unused resources
prune:
    docker system prune -f

# Show Docker Compose configuration
config:
    docker compose -f {{compose_file}} -p {{project_name}} config

ollama pull:
    sudo docker compose exec ollama ollama run llama3  
