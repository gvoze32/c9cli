#!/bin/bash

# Fungsi untuk mendapatkan token join
get_join_token() {
    local type=$1
    docker swarm join-token -q "$type"
}

# Fungsi untuk inisialisasi swarm manager
init_manager() {
    echo "Initializing Swarm Manager..."

    # Get public IP
    PUBLIC_IP=$(curl -s ifconfig.me)

    # Initialize swarm
    if ! docker info | grep -q "Swarm: active"; then
        docker swarm init --advertise-addr "$PUBLIC_IP" || {
            echo "Failed to initialize swarm"
            exit 1
        }

        # Get tokens
        MANAGER_TOKEN=$(get_join_token manager)
        WORKER_TOKEN=$(get_join_token worker)

        echo "Swarm initialized successfully!"
        echo "Manager Token: $MANAGER_TOKEN"
        echo "Worker Token: $WORKER_TOKEN"
        echo
        echo "To add a manager node, run:"
        echo "docker swarm join --token $MANAGER_TOKEN $PUBLIC_IP:2377"
        echo
        echo "To add a worker node, run:"
        echo "docker swarm join --token $WORKER_TOKEN $PUBLIC_IP:2377"

        # Create overlay network
        docker network create --driver overlay --attachable c9net

        # Setup custom labels
        docker node update --label-add role=manager "$(docker info -f '{{.Swarm.NodeID}}')"

        # Create configs directory
        mkdir -p /etc/docker/swarm/configs

        echo "Swarm manager setup complete!"
    else
        echo "Swarm is already initialized on this node"
        echo "Current tokens:"
        echo "Manager Token: $(get_join_token manager)"
        echo "Worker Token: $(get_join_token worker)"
    fi
}

# Fungsi untuk promosi node ke manager
promote_node() {
    local node=$1
    echo "Promoting node $node to manager..."
    docker node promote "$node"
}

# Fungsi untuk demosi node dari manager
demote_node() {
    local node=$1
    echo "Demoting node $node to worker..."
    docker node demote "$node"
}

# Fungsi untuk melihat status node
node_status() {
    echo "Current node status:"
    docker node ls
}

# Menu utama
case "$1" in
init)
    init_manager
    ;;
promote)
    if [ -z "$2" ]; then
        echo "Usage: $0 promote <node-id>"
        exit 1
    fi
    promote_node "$2"
    ;;
demote)
    if [ -z "$2" ]; then
        echo "Usage: $0 demote <node-id>"
        exit 1
    fi
    demote_node "$2"
    ;;
status)
    node_status
    ;;
*)
    echo "Usage: $0 {init|promote|demote|status}"
    echo "Commands:"
    echo "  init              Initialize swarm manager"
    echo "  promote <node>    Promote node to manager"
    echo "  demote <node>     Demote node to worker"
    echo "  status            Show nodes status"
    exit 1
    ;;
esac
