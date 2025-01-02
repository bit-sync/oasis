# Custom Debian Repository

This is a custom Debian package repository for hosting and distributing .deb packages.

## Repository Structure

```
repo/
├── pool/
│   └── main/         # Place your .deb packages here
└── dists/
    └── stable/
        └── universe/
            └── binary-amd64/
```

## Usage

### Adding Packages

1. Place your .deb packages in the `repo/pool/main/` directory
2. Run the update script:
   ```bash
   ./update-repo.sh
   ```

### Using the Repository

To use this repository in your Debian/Ubuntu system:

1. Add the repository to your sources:
   ```bash
   echo "deb [trusted=yes] file:///path/to/repo stable universe" | sudo tee /etc/apt/sources.list.d/custom.list
   ```
   Replace `/path/to/repo` with the actual path to the repository.

2. Update your package lists:
   ```bash
   sudo apt update
   ```

3. Install packages from the repository:
   ```bash
   sudo apt install package-name
   ```

## Maintenance

- Run `./update-repo.sh` whenever you add, remove, or modify packages in the repository
- The script will automatically update the package indices and generate necessary metadata files
