#!/bin/bash

NODES_FILE="/etc/docker/swarm/nodes.conf"
BACKUP_DRIVE="gdrive"
BACKUP_FOLDER="c9backup"

check_node_health() {
    local node=$1
    docker node inspect "$node" --format '{{.Status.State}}' 2>/dev/null
}

handle_node_failure() {
    local failed_node=$1

    # Get affected services
    affected_services=$(docker service ls --filter node="$failed_node" --format '{{.Name}}')

    for service in $affected_services; do
        username=${service#c9-}
        echo "Handling failover for user: $username"

        # Get latest backup
        latest_backup=$(rclone lsl "$BACKUP_DRIVE:$BACKUP_FOLDER" --include "*-$username-*" | sort -k2 | tail -n1 | awk '{print $NF}')

        if [ -n "$latest_backup" ]; then
            # Create temporary directory
            temp_dir=$(mktemp -d)

            # Download and extract backup
            rclone copy "$BACKUP_DRIVE:$BACKUP_FOLDER/$latest_backup" "$temp_dir/"

            # Get service config
            port=$(docker service inspect "$service" --format '{{range .Endpoint.Ports}}{{.PublishedPort}}{{end}}')
            memory=$(docker service inspect "$service" --format '{{range .TaskTemplate.Resources.Limits}}{{.MemoryBytes}}{{end}}')
            cpu=$(docker service inspect "$service" --format '{{range .TaskTemplate.Resources.Limits}}{{.NanoCPUs}}{{end}}')

            # Update service with new placement
            docker service update \
                --force \
                --constraint-rm "node==$failed_node" \
                --mount-add type=bind,source="$temp_dir",target=/workspace \
                "$service"

            # Cleanup
            rm -rf "$temp_dir"
            echo "Service $service restored from backup and relocated"
        else
            echo "No backup found for $username"
        fi
    done
}

monitor_nodes() {
    while true; do
        while read -r node_id node_name; do
            status=$(check_node_health "$node_id")

            if [ "$status" != "ready" ]; then
                echo "Node $node_name ($node_id) is down"
                handle_node_failure "$node_id"
            fi
        done <"$NODES_FILE"

        sleep 30
    done
}

# Start monitoring
monitor_nodes
