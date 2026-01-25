# ☕ Java Management Guide (SDKMAN)

This project uses **SDKMAN!** to manage multiple versions of Java. Here is how to switch versions or set up the default environment.

## 1. Check Version

Beyond the standard commands, this project provides a convenience alias:

*   `java -version`: Standard command (all versions)
*   `java --version`: Standard command (Java 9+)
*   `java -v`: **[Convenience]** Short alias for quick version checking.

## 2. Set Default Version

To set the global default Java version (for all shells):

```bash
# List installed versions
sdk list java

# Set a specific version as default (e.g., Java 21)
sdk default java 21.0.2-tem
```

## 3. Temporary Version (Current Session Only)

Use this when you want to switch versions temporarily in the current terminal session:

```bash
# Use Java 17 only in current session
sdk use java 17.0.10-tem
```

## 4. Installing New Java Versions

```bash
# List available versions to install
sdk list java

# Install a specific version (e.g., 23-tem)
sdk install java 23-tem
```

## 💡 Notes
*   **Shell Support**: SDKMAN is automatically loaded in both `zsh` and `bash`.
*   **Global Path**: A symbolic link is maintained at `/usr/local/bin/java` (if configured) so that external scripts can use the `java` command even without loading environment variables.