package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/zangzang/oh-my-shellscript/internal/config"
	"github.com/zangzang/oh-my-shellscript/internal/module"
	"github.com/zangzang/oh-my-shellscript/internal/ui"
)

func main() {
	var scriptDir string
	
	// First, check environment variable
	if envDir := os.Getenv("SETUP_BASE_DIR"); envDir != "" && fileExists(filepath.Join(envDir, "modules")) {
		scriptDir = envDir
	} else {
		// Get the directory where the executable/script is located
		exePath, err := os.Executable()
		if err != nil {
			exePath = os.Args[0]
		}

		scriptDir = filepath.Dir(exePath)
		
		// Try multiple possible locations for linux-setup
		if !fileExists(filepath.Join(scriptDir, "modules")) {
			// Try parent directory
			parentDir := filepath.Dir(scriptDir)
			if fileExists(filepath.Join(parentDir, "linux-setup", "modules")) {
				scriptDir = filepath.Join(parentDir, "linux-setup")
			} else if fileExists(filepath.Join(parentDir, "modules")) {
				scriptDir = parentDir
			} else if fileExists(filepath.Join(scriptDir, "..", "linux-setup", "modules")) {
				// Go two levels up
				absParent, _ := filepath.Abs(filepath.Join(scriptDir, ".."))
				scriptDir = filepath.Join(absParent, "linux-setup")
			}
		}
	}

	// Parse command line flags
	preset := flag.String("preset", "", "Load a preset by name or path")
	execute := flag.Bool("execute", false, "Execute installation immediately")
	dryRun := flag.Bool("dry-run", false, "Show installation plan without executing")
	postModuleMode := flag.String("post-module-mode", "", "Post-module mode: always|selected|preset (default: selected)")
	flag.Parse()

	// Initialize paths
	paths := config.NewPaths(scriptDir)
	if err := paths.EnsureDirs(); err != nil {
		log.Fatalf("Failed to ensure directories: %v", err)
	}

	// Create module manager
	mgr, err := module.NewManager(paths.ModulesDir, paths.ConfigDir, paths.PresetsDir)
	if err != nil {
		log.Fatalf("Failed to initialize module manager: %v", err)
	}

	resolvedPostMode := strings.TrimSpace(*postModuleMode)
	if resolvedPostMode == "" {
		resolvedPostMode = strings.TrimSpace(os.Getenv("OMSS_POST_MODULE_MODE"))
	}
	if err := mgr.SetPostModuleMode(resolvedPostMode); err != nil {
		log.Fatalf("Invalid post module mode: %v", err)
	}

	// Load preset if specified
	if *preset != "" {
		var presetPath string
		
		// Check if it's an absolute path
		if filepath.IsAbs(*preset) && fileExists(*preset) {
			presetPath = *preset
		} else if fileExists(filepath.Join(paths.PresetsDir, *preset+".json")) {
			// Try with .json extension in presets directory  
			presetPath = filepath.Join(paths.PresetsDir, *preset+".json")
		} else if fileExists(*preset) {
			// Try as-is
			presetPath = *preset
		}
		
		if presetPath != "" {
			if err := mgr.LoadPreset(presetPath, true); err != nil {
				fmt.Printf("Warning: Failed to load preset %s: %v\n", *preset, err)
			}
		} else {
			fmt.Printf("Warning: Preset not found: %s (checked: %s)\n", *preset, filepath.Join(paths.PresetsDir, *preset+".json"))
		}
	}

	if *preset == "" && !*execute && !*dryRun {
		sessionPath := filepath.Join(paths.ConfigDir, "last_session.json")
		if loaded, err := loadLastSession(sessionPath); err == nil && len(loaded) > 0 {
			if askLoadLastSession(loaded) {
				applySelection(mgr, loaded)
				fmt.Printf("✅ Last session loaded (%d)\n", len(mgr.GetSelectedItems()))
			} else {
				fmt.Println("🆕 Starting with clean selection.")
			}
		}
	}

	// Create installer
	installer := module.NewInstaller(mgr, paths.ModulesDir)

	// Handle immediate execution modes
	if *dryRun {
		if len(mgr.GetSelectedItems()) == 0 {
			fmt.Println("No modules selected for simulation")
			os.Exit(1)
		}
		installList := mgr.ResolveDependencies()
		_ = saveLastSession(filepath.Join(paths.ConfigDir, "last_session.json"), mgr.GetSelectedItems())
		installer.RunDryRun(installList)
		os.Exit(0)
	}

	if *execute {
		if len(mgr.GetSelectedItems()) == 0 {
			fmt.Println("No modules selected for installation")
			os.Exit(1)
		}
		installList := mgr.ResolveDependencies()
		selectedItems := mgr.GetSelectedItems()
		_ = saveLastSession(filepath.Join(paths.ConfigDir, "last_session.json"), selectedItems)
		if err := installer.Run(installList, selectedItems); err != nil {
			fmt.Printf("Installation error: %v\n", err)
			os.Exit(1)
		}
		os.Exit(0)
	}

	// Run interactive UI
	model := ui.NewModel(mgr, paths.PresetsDir)
	p := tea.NewProgram(model, tea.WithAltScreen())
	finalModel, err := p.Run()
	if err != nil {
		fmt.Printf("Error running UI: %v\n", err)
		os.Exit(1)
	}

	uiModel := finalModel.(*ui.Model)
	selectedItems := uiModel.GetSelectedItems()
	_ = saveLastSession(filepath.Join(paths.ConfigDir, "last_session.json"), selectedItems)

	if !uiModel.ShouldRunInstall() {
		os.Exit(0)
	}

	installList := uiModel.GetInstallList()

	if len(installList) > 0 {
		if err := installer.RunInteractive(installList, selectedItems); err != nil {
			fmt.Printf("Installation error: %v\n", err)
			os.Exit(1)
		}
	}
}

// fileExists checks if a file exists
func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func loadLastSession(path string) ([]string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var items []string
	if err := json.Unmarshal(data, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func saveLastSession(path string, items []string) error {
	data, err := json.MarshalIndent(items, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

func askLoadLastSession(items []string) bool {
	clearScreen()

	border := strings.Repeat("=", 64)
	fmt.Println()
	fmt.Println(border)
	fmt.Println("📂 Last Session Found")
	fmt.Printf("Total modules: %d\n", len(items))
	fmt.Println(strings.Repeat("-", 64))

	maxShow := len(items)
	if maxShow > 10 {
		maxShow = 10
	}
	for i := 0; i < maxShow; i++ {
		fmt.Printf("%2d. %s\n", i+1, items[i])
	}
	if len(items) > maxShow {
		fmt.Printf("... and %d more\n", len(items)-maxShow)
	}

	fmt.Println(strings.Repeat("-", 64))
	fmt.Print("Load this selection and continue? (Y/n): ")

	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	choice := strings.ToLower(strings.TrimSpace(input))
	fmt.Println(border)

	return choice == "" || choice == "y" || choice == "yes"
}

func clearScreen() {
	fmt.Print("\033[H\033[2J\033[3J")
}

func applySelection(mgr *module.Manager, items []string) {
	for _, id := range items {
		if id == "" {
			continue
		}
		if mgr.GetModule(id) == nil {
			continue
		}
		if !mgr.IsSelected(id) {
			mgr.Toggle(id)
		}
	}
}

