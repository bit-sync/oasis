#!/bin/bash

REPO_DIR="repo"
DIST="stable"
ARCH="amd64"

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo
    echo "Commands:"
    echo "  create-component COMPONENT   Create a new component (e.g., main, universe)"
    echo "  update COMPONENT            Update package indices for a component"
    echo "  update-all                  Update all components"
    echo "  list                        List all components"
    echo
    echo "Options:"
    echo "  -h, --help                 Show this help message"
}

# Function to create component structure
create_component() {
    local component=$1
    
    if [ -z "$component" ]; then
        echo "Error: Component name is required"
        exit 1
    fi
    
    echo "Creating component: $component"
    mkdir -p "${REPO_DIR}/pool/${component}"
    mkdir -p "${REPO_DIR}/dists/${DIST}/${component}/binary-${ARCH}"
    
    echo "Component '$component' created successfully"
    echo "Place .deb packages in: ${REPO_DIR}/pool/${component}/"
}

# Function to update a single component
update_component() {
    local component=$1
    
    if [ ! -d "${REPO_DIR}/pool/${component}" ]; then
        echo "Error: Component '$component' does not exist"
        exit 1
    fi
    
    echo "Updating component: $component"
    
    # Ensure indices directory exists
    mkdir -p "${REPO_DIR}/indices"
    
    # Create override file if it doesn't exist
    OVERRIDE_FILE="${REPO_DIR}/indices/override.${DIST}.${component}"
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo "# Format: package_name priority section maintainer" > "$OVERRIDE_FILE"
    fi
    
    # Generate Packages file
    cd "${REPO_DIR}/pool/${component}"
    if [ -s "../../indices/override.${DIST}.${component}" ]; then
        # Use override file if it exists and is not empty
        dpkg-scanpackages . ../../indices/override.${DIST}.${component} > "../../dists/${DIST}/${component}/binary-${ARCH}/Packages"
    else
        # Skip override file if it doesn't exist or is empty
        dpkg-scanpackages . /dev/null > "../../dists/${DIST}/${component}/binary-${ARCH}/Packages"
    fi
    gzip -kf "../../dists/${DIST}/${component}/binary-${ARCH}/Packages"
    
    echo "Component '$component' updated successfully"
}

# Function to list all components
list_components() {
    echo "Available components:"
    if [ -d "${REPO_DIR}/pool" ]; then
        ls -1 "${REPO_DIR}/pool"
    else
        echo "No components found"
    fi
}

# Function to update Release file
update_release() {
    # Create dists/stable directory if it doesn't exist
    mkdir -p "${REPO_DIR}/dists/${DIST}"
    cd "${REPO_DIR}/dists/${DIST}"
    
    # Get all components
    components=$(ls -1 "${REPO_DIR}/pool" 2>/dev/null || echo "")
    
    if [ -z "$components" ]; then
        echo "Warning: No components found in ${REPO_DIR}/pool"
        return 1
    fi
    
    # Generate Release file
    cat > Release << EOF
Origin: Oasis Repository
Label: Oasis Repository
Suite: ${DIST}
Codename: ${DIST}
Version: 1.0
Architectures: ${ARCH}
Components: $(echo $components | tr ' ' ' ')
Description: Open debian package repository
Date: $(date -Ru)
EOF

    # Add file hashes only if there are Packages files
    if find . -type f -name "Packages*" > /dev/null 2>&1; then
        {
            echo "MD5Sum:"
            find . -type f -name "Packages*" -exec sh -c 'echo " $(md5sum "{}" | cut -d" " -f1) $(wc -c < "{}") {}"' \;
            echo "SHA1:"
            find . -type f -name "Packages*" -exec sh -c 'echo " $(sha1sum "{}" | cut -d" " -f1) $(wc -c < "{}") {}"' \;
            echo "SHA256:"
            find . -type f -name "Packages*" -exec sh -c 'echo " $(sha256sum "{}" | cut -d" " -f1) $(wc -c < "{}") {}"' \;
        } >> Release
    fi
}

# Function to update all components
update_all() {
    if [ ! -d "${REPO_DIR}/pool" ]; then
        echo "Error: No components found"
        exit 1
    fi
    
    for component in $(ls -1 "${REPO_DIR}/pool"); do
        update_component "$component"
    done
    
    update_release
    echo "All components updated successfully"
}

# Main script logic
case "$1" in
    create-component)
        create_component "$2"
        ;;
    update)
        update_component "$2"
        update_release
        ;;
    update-all)
        update_all
        ;;
    list)
        list_components
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        usage
        exit 1
        ;;
esac
