package module

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Installer handles the installation process
type Installer struct {
	manager    *Manager
	modulesDir string
}

// NewInstaller creates a new installer
func NewInstaller(mgr *Manager, modulesDir string) *Installer {
	return &Installer{
		manager:    mgr,
		modulesDir: modulesDir,
	}
}

// RunDryRun shows what would be installed
func (i *Installer) RunDryRun(installList []string) {
	fmt.Println("\n" + "═" + " Installation Sequence (Simulation)")
	fmt.Println("═════════════════════════════════════════════════")
	fmt.Println()

	for idx, item := range installList {
		mod := i.manager.GetModule(item)
		if mod != nil {
			variant := ""
			parts := strings.SplitN(item, ":", 2)
			if len(parts) == 2 {
				variant = parts[1]
			}

			fmt.Printf("  %2d. %s\n", idx+1, mod.Name)
			if variant != "" {
				fmt.Printf("      └─ ID: %s:%s\n", mod.ID, variant)
			} else {
				fmt.Printf("      └─ ID: %s\n", mod.ID)
			}

			installScript := filepath.Join(i.modulesDir, strings.ReplaceAll(mod.ID, ".", "/"), "install.sh")
			if _, err := os.Stat(installScript); err == nil {
				if variant != "" {
					fmt.Printf("      └─ Script: install.sh %s\n", variant)
				} else {
					fmt.Printf("      └─ Script: install.sh\n")
				}
			} else {
				fmt.Printf("      └─ ⚠️ install.sh not found\n")
			}
		} else {
			fmt.Printf("  %2d. %s (⚠️ Metadata not found)\n", idx+1, item)
		}
	}

	fmt.Println()
	fmt.Println("🔍 Simulation Mode - No actual changes made")
	fmt.Println()
}

// Run executes the installation
func (i *Installer) Run(installList []string, selectedItems []string) error {
	fmt.Println("\n" + "═" + " Installing Modules")
	fmt.Println("═════════════════════════════════════════════════")
	fmt.Println()

	successCount := 0
	failCount := 0
	type installFailure struct {
		name   string
		reason string
	}
	var succeeded []string
	var failed []installFailure

	for idx, item := range installList {
		mod := i.manager.GetModule(item)
		if mod == nil {
			fmt.Printf("[%d/%d] ❌ %s (Module not found)\n", idx+1, len(installList), item)
			failCount++
			failed = append(failed, installFailure{name: item, reason: "module metadata not found"})
			continue
		}

		variant := ""
		parts := strings.SplitN(item, ":", 2)
		if len(parts) == 2 {
			variant = parts[1]
		}

		displayName := mod.Name
		if variant != "" {
			displayName = fmt.Sprintf("%s (v%s)", mod.Name, variant)
		}
		fmt.Printf("[%d/%d] 🔄 Installing: %s\n", idx+1, len(installList), displayName)

		// Find install script
		modPath := filepath.Join(i.modulesDir, strings.ReplaceAll(mod.ID, ".", string(filepath.Separator)))
		installScript := filepath.Join(modPath, "install.sh")

		if _, err := os.Stat(installScript); err != nil {
			fmt.Printf("        └─ ⚠️ install.sh not found at %s\n", installScript)
			failCount++
			failed = append(failed, installFailure{name: displayName, reason: "install.sh not found"})
			continue
		}

		// Run install script
		cmdArgs := []string{installScript}
		if variant != "" {
			cmdArgs = append(cmdArgs, variant)
		}
		cmd := exec.Command("bash", cmdArgs...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		cmd.Stdin = os.Stdin

		if err := cmd.Run(); err != nil {
			fmt.Printf("        └─ ❌ Installation failed: %v\n", err)
			failCount++
			failed = append(failed, installFailure{name: displayName, reason: err.Error()})
		} else {
			fmt.Printf("        └─ ✅ Installed successfully\n")
			successCount++
			succeeded = append(succeeded, displayName)
		}

		fmt.Println()
	}

	// Summary
	fmt.Println("═════════════════════════════════════════════════")
	fmt.Printf("✅ Success: %d\n", successCount)
	fmt.Printf("❌ Failed: %d\n", failCount)

	if len(succeeded) > 0 {
		fmt.Println("\n✅ Succeeded Modules")
		for _, name := range succeeded {
			fmt.Printf("  - %s\n", name)
		}
	}

	if len(failed) > 0 {
		fmt.Println("\n❌ Failed Modules")
		for _, item := range failed {
			fmt.Printf("  - %s: %s\n", item.name, item.reason)
		}
	}
	fmt.Println()

	if failCount > 0 {
		return fmt.Errorf("installation completed with %d failures", failCount)
	}

	return nil
}

// RunInteractive provides interactive installation
func (i *Installer) RunInteractive(installList []string, selectedItems []string) error {
	fmt.Println("\n" + strings.Repeat("═", 50))
	fmt.Println("  Installation Plan")
	fmt.Println(strings.Repeat("═", 50))
	fmt.Println()

	for idx, item := range installList {
		mod := i.manager.GetModule(item)
		if mod != nil {
			variant := ""
			parts := strings.SplitN(item, ":", 2)
			if len(parts) == 2 {
				variant = parts[1]
			}

			displayName := mod.Name
			if variant != "" {
				displayName = fmt.Sprintf("%s (%s)", mod.Name, variant)
			}

			fmt.Printf("  %2d. %s\n", idx+1, displayName)
		} else {
			fmt.Printf("  %2d. %s\n", idx+1, item)
		}
	}

	fmt.Println()
	fmt.Printf("Total modules to install: %d\n", len(installList))
	fmt.Println()

	// Ask for confirmation
	fmt.Print("Do you want to proceed? (y/N): ")
	var response string
	fmt.Scanln(&response)

	if strings.ToLower(response) != "y" {
		fmt.Println("Installation cancelled.")
		return nil
	}

	fmt.Println()
	return i.Run(installList, selectedItems)
}

// SaveSelection saves the current selection for later
func (i *Installer) SaveSelection(filename string, selectedItems []string) error {
	// Try to save to a well-known location
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}

	saveDir := filepath.Join(homeDir, ".config", "oh-my-shellscript")
	if err := os.MkdirAll(saveDir, 0755); err != nil {
		return err
	}

	savePath := filepath.Join(saveDir, filename)
	fmt.Printf("Selection saved to: %s\n", savePath)

	// Create content
	var content strings.Builder
	content.WriteString(fmt.Sprintf("# Saved at: %s\n", time.Now().Format(time.RFC3339)))
	content.WriteString(fmt.Sprintf("# Total modules: %d\n\n", len(selectedItems)))

	for _, item := range selectedItems {
		content.WriteString(item + "\n")
	}

	return os.WriteFile(savePath, []byte(content.String()), 0644)
}
