# VSCode Extension Auto-Installation Guide

You can automatically install language-specific extensions when installing VSCode.

## 📋 Available Extension Groups

| Group | Description | Included Examples |
| :--- | :--- | :--- |
| **base** | Essential for all | Git, Docker, YAML, Prettier, ESLint |
| **java** | Java Dev | Red Hat Java, Maven, Spring Boot |
| **dotnet** | .NET Dev | C# Dev Kit, SQL Tools |
| **node** | Node.js Dev | Node.js Pack, Jest |
| **python** | Python Dev | Python, Pylance, Black |
| **rust** | Rust Dev | Rust Analyzer, TOML |

## 🚀 CLI Usage

```bash
# Install VSCode with Java and .NET extensions
# (Note: Logic varies based on implementation, typically passed via env or args)
```

## 📂 Structure
Extensions are defined in `modules/gui/vscode/extensions/*.json`.

Example `java.json`:
```json
{
  "name": "Java Development",
  "description": "Extensions for Java development",
  "extensions": [
    "vscjava.vscode-java-pack",
    "vmware.vscode-spring-boot-dashboard"
  ]
}
```

## 💡 Notes
1. **Base is automatic**: The `base` group is usually included by default.
2. **De-duplication**: Extensions are only installed once even if they belong to multiple groups.
3. **Internet Required**: Extensions are downloaded from the VSCode Marketplace.