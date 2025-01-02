# Custom Debian Repository

This is a custom Debian package repository for hosting and distributing .deb packages.

## Repository Structure

```
repo/
├── pool/
│   └── universe/              # Component name
│       └── h/                 # First letter of package
│           └── hex/          # Package name
│               └── hex-amd64-1.2.deb
└── dists/
    └── universe/
        └── binary-amd64/
            ├── Packages
            ├── Packages.gz
            └── Release
```

## Usage

### Adding Packages

1. Place your .deb packages in the `repo/pool/universe/` directory
2. Run the update script:
   ```bash
   ./manage-repo.sh update-all
   ```
   The script will automatically organize packages into the correct directory structure.

### Using the Repository

To use this repository in your Debian/Ubuntu system:

1. Get the sources.list entry:
   ```bash
   ./manage-repo.sh sources
   ```

2. Add the output to `/etc/apt/sources.list.d/oasis.list`

3. Update your package lists:
   ```bash
   sudo apt update
   ```

4. Install packages from the repository:
   ```bash
   sudo apt install package-name
   ```

## Repository Components

- `universe`: Main component for all packages

## Maintenance

- Run `./manage-repo.sh update-all` whenever you add, remove, or modify packages in the repository
- The script will automatically:
  - Organize packages into the correct directory structure
  - Update package indices
  - Generate necessary metadata files
