#!/bin/bash

REPO_DIR="repo"
ARCH="amd64"
REPO_URL="https://oasis.bitsyncdev.com"

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo
    echo "Commands:"
    echo "  create-component COMPONENT   Create a new component (e.g., main, universe)"
    echo "  update COMPONENT            Update package indices for a component"
    echo "  update-all                  Update all components"
    echo "  list                        List all components"
    echo "  sources                     Generate sources.list entry"
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
    mkdir -p "${REPO_DIR}/dists/${component}/binary-${ARCH}"
    
    echo "Component '$component' created successfully"
    echo "Place .deb packages in: ${REPO_DIR}/pool/${component}/"
}

# Function to organize package in pool
organize_package() {
    local component=$1
    local package_file=$2
    
    # Extract package name from filename (assumes name-version-arch.deb format)
    local package_name=$(echo "$package_file" | sed -E 's/^([^_-]+).*/\1/')
    local first_letter="${package_name:0:1}"
    
    # Create package directory structure
    local package_dir="${REPO_DIR}/pool/${component}/${first_letter}/${package_name}"
    mkdir -p "$package_dir"
    
    # Move package to its directory
    mv "$package_file" "$package_dir/"
    echo "Organized package $package_file into $package_dir"
}

# Function to update a single component
update_component() {
    local component=$1
    
    echo "Updating component: $component"
    
    # Ensure indices directory exists
    mkdir -p "${REPO_DIR}/indices"
    mkdir -p "${REPO_DIR}/dists/${component}/binary-${ARCH}"
    
    # Create override file if it doesn't exist
    OVERRIDE_FILE="${REPO_DIR}/indices/override.${component}"
    if [ ! -f "$OVERRIDE_FILE" ]; then
        echo "# Format: package_name priority section maintainer" > "$OVERRIDE_FILE"
    fi
    
    # Find any unorganized packages and organize them
    find "${REPO_DIR}/pool/${component}" -maxdepth 1 -name "*.deb" -exec bash -c 'organize_package "$0" "$1"' "$component" {} \;
    
    # Generate Packages file
    cd "${REPO_DIR}"
    if [ -s "indices/override.${component}" ]; then
        # Use override file if it exists and is not empty
        dpkg-scanpackages "pool/${component}" "indices/override.${component}" > "dists/${component}/binary-${ARCH}/Packages"
    else
        # Skip override file if it doesn't exist or is empty
        dpkg-scanpackages "pool/${component}" /dev/null > "dists/${component}/binary-${ARCH}/Packages"
    fi
    gzip -kf "dists/${component}/binary-${ARCH}/Packages"
    
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
    components=$(ls -1 "${REPO_DIR}/pool" 2>/dev/null || echo "")
    
    # Generate Release file for each component
    for component in $components; do
        cd "${REPO_DIR}/dists/${component}"
        cat > Release << EOF
Origin: Oasis Repository
Label: Oasis Repository
Component: ${component}
Architecture: ${ARCH}
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
    done
}

# Function to update all components
update_all() {
    mkdir -p "${REPO_DIR}/pool"
    
    components=$(ls -1 "${REPO_DIR}/pool" 2>/dev/null || echo "")
    if [ -z "$components" ]; then
        echo "No components found in pool directory"
        exit 0
    fi
    
    for component in $components; do
        update_component "$component"
    done
    
    update_release
    echo "All components updated successfully"
}

# Function to show sources.list entry
show_sources_list() {
    mkdir -p "${REPO_DIR}/pool"
    
    components=$(ls -1 "${REPO_DIR}/pool" 2>/dev/null || echo "")
    if [ -z "$components" ]; then
        echo "# Oasis Repository"
        echo "# No components available yet"
        return 0
    fi
    
    echo "# Oasis Repository"
    for component in $components; do
        echo "deb ${REPO_URL} ${component} ."
    done
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
    sources)
        show_sources_list
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
