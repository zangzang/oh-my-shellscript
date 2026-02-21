package config

import (
	"os"
	"path/filepath"
)

// Paths holds all important directory paths
type Paths struct {
	ModulesDir string
	ConfigDir  string
	PresetsDir string
	BaseDir    string
}

// NewPaths creates paths based on the script location
func NewPaths(scriptDir string) *Paths {
	baseDir, _ := filepath.Abs(scriptDir)

	return &Paths{
		BaseDir:    baseDir,
		ModulesDir: filepath.Join(baseDir, "modules"),
		ConfigDir:  filepath.Join(baseDir, "config"),
		PresetsDir: filepath.Join(baseDir, "presets"),
	}
}

// EnsureDirs ensures all required directories exist
func (p *Paths) EnsureDirs() error {
	dirs := []string{p.ModulesDir, p.ConfigDir, p.PresetsDir}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return err
		}
	}
	return nil
}
