package module

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const (
	PostModuleModeSelected = "selected"
	PostModuleModeAlways   = "always"
	PostModuleModePreset   = "preset"
)

type variantObject struct {
	Value    string `json:"value"`
	Selected *bool  `json:"selected"`
}

// Manager handles all module operations
type Manager struct {
	modules        map[string]*ModuleInfo
	categories     map[string]*CategoryInfo
	selected       map[string]bool
	selectedSource map[string]string
	contextItems   map[string]bool
	postModuleMode string
	modulesDir     string
	configDir      string
	presetsDir     string
}

// NewManager creates a new module manager
func NewManager(modulesDir, configDir, presetsDir string) (*Manager, error) {
	m := &Manager{
		modules:      make(map[string]*ModuleInfo),
		categories:   make(map[string]*CategoryInfo),
		selected:     make(map[string]bool),
		selectedSource: make(map[string]string),
		contextItems: make(map[string]bool),
		postModuleMode: PostModuleModeSelected,
		modulesDir:   modulesDir,
		configDir:    configDir,
		presetsDir:   presetsDir,
	}

	if err := m.loadModules(); err != nil {
		return nil, err
	}

	return m, nil
}

func (m *Manager) SetPostModuleMode(mode string) error {
	if mode == "" {
		mode = PostModuleModeSelected
	}

	switch mode {
	case PostModuleModeSelected, PostModuleModeAlways, PostModuleModePreset:
		m.postModuleMode = mode
		return nil
	default:
		return fmt.Errorf("invalid post module mode: %s (allowed: always|selected|preset)", mode)
	}
}

// loadModules scans the modules directory and loads all metadata
func (m *Manager) loadModules() error {
	err := filepath.Walk(m.modulesDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.Name() == "meta.json" {
			return m.loadModuleMetadata(path)
		}
		return nil
	})

	return err
}

// loadModuleMetadata loads a single module's metadata
func (m *Manager) loadModuleMetadata(metaPath string) error {
	data, err := os.ReadFile(metaPath)
	if err != nil {
		return err
	}

	var raw struct {
		ID          string          `json:"id"`
		Name        string          `json:"name"`
		Description string          `json:"description"`
		Category    string          `json:"category"`
		Requires    []string        `json:"requires,omitempty"`
		PostModules []string        `json:"post_modules,omitempty"`
		Variants    json.RawMessage `json:"variants,omitempty"`
	}
	if err := json.Unmarshal(data, &raw); err != nil {
		return fmt.Errorf("failed to unmarshal %s: %w", metaPath, err)
	}

	moduleInfo := ModuleInfo{
		ID:          raw.ID,
		Name:        raw.Name,
		Description: raw.Description,
		Category:    raw.Category,
		Requires:    raw.Requires,
		PostModules: raw.PostModules,
		Variants:    []string{},
	}

	if len(raw.Variants) > 0 {
		var stringVariants []string
		if err := json.Unmarshal(raw.Variants, &stringVariants); err == nil {
			moduleInfo.Variants = append(moduleInfo.Variants, stringVariants...)
		} else {
			var objectVariants []variantObject
			if err := json.Unmarshal(raw.Variants, &objectVariants); err == nil {
				for _, variant := range objectVariants {
					if variant.Value == "" {
						continue
					}
					moduleInfo.Variants = append(moduleInfo.Variants, variant.Value)
					if moduleInfo.DefaultVariant == "" && variant.Selected != nil && *variant.Selected {
						moduleInfo.DefaultVariant = variant.Value
					}
				}
			}
		}
	}

	if moduleInfo.ID == "" {
		return nil
	}

	m.modules[moduleInfo.ID] = &moduleInfo

	// Dynamic category assignment
	catPath := strings.Split(moduleInfo.Category, "/")
	topCat := catPath[0]

	if _, exists := m.categories[topCat]; !exists {
		m.categories[topCat] = &CategoryInfo{
			Name:          strings.Title(strings.ToLower(topCat)),
			Order:         999,
			Modules:       []string{},
			Subcategories: make(map[string]*SubcategoryInfo),
		}
	}

	targetCat := m.categories[topCat]

	if len(catPath) > 1 {
		subCat := catPath[1]
		if _, exists := targetCat.Subcategories[subCat]; !exists {
			targetCat.Subcategories[subCat] = &SubcategoryInfo{
				Name:    strings.Title(strings.ToLower(subCat)),
				Modules: []string{},
			}
		}

		if !contains(targetCat.Subcategories[subCat].Modules, moduleInfo.ID) {
			targetCat.Subcategories[subCat].Modules = append(
				targetCat.Subcategories[subCat].Modules,
				moduleInfo.ID,
			)
		}
	} else {
		if !contains(targetCat.Modules, moduleInfo.ID) {
			targetCat.Modules = append(targetCat.Modules, moduleInfo.ID)
		}
	}

	return nil
}

func (m *Manager) normalizeSelectionID(id string) string {
	if strings.Contains(id, ":") {
		return id
	}
	mod := m.GetModule(id)
	if mod == nil {
		return id
	}
	if mod.DefaultVariant != "" {
		return id + ":" + mod.DefaultVariant
	}
	return id
}

func (m *Manager) normalizeDependencyID(id string) string {
	if strings.Contains(id, ":") {
		return id
	}

	mod := m.GetModule(id)
	if mod == nil || len(mod.Variants) == 0 {
		return id
	}

	prefix := id + ":"
	var selectedVariants []string
	for selectedID := range m.selected {
		if strings.HasPrefix(selectedID, prefix) {
			selectedVariants = append(selectedVariants, selectedID)
		}
	}

	if len(selectedVariants) > 0 {
		sort.Strings(selectedVariants)
		return selectedVariants[0]
	}

	if mod.DefaultVariant != "" {
		return id + ":" + mod.DefaultVariant
	}

	return id
}

// GetModule retrieves a module by ID
func (m *Manager) GetModule(id string) *ModuleInfo {
	if mod, exists := m.modules[id]; exists {
		return mod
	}
	// Try without variant
	baseID := strings.Split(id, ":")[0]
	return m.modules[baseID]
}

// Toggle toggles selection of a module
func (m *Manager) Toggle(id string) {
	id = m.normalizeSelectionID(id)
	if m.selected[id] {
		delete(m.selected, id)
		delete(m.selectedSource, id)
		m.contextItems[id] = false
	} else {
		m.selected[id] = true
		m.selectedSource[id] = "interactive"
		m.contextItems[id] = true
	}
}

// IsSelected returns whether a module is selected
func (m *Manager) IsSelected(id string) bool {
	return m.selected[id]
}

// ResolveDependencies resolves dependencies and returns installation order
func (m *Manager) ResolveDependencies() []string {
	var result []string
	visited := make(map[string]bool)

	var resolve func(string, bool, string)
	resolve = func(itemID string, explicit bool, source string) {
		if visited[itemID] {
			return
		}
		visited[itemID] = true

		if mod := m.GetModule(itemID); mod != nil {
			for _, dep := range mod.Requires {
				resolve(m.normalizeDependencyID(dep), false, "")
			}
		}

		result = append(result, itemID)

		runPostModules := false
		switch m.postModuleMode {
		case PostModuleModeAlways:
			runPostModules = true
		case PostModuleModeSelected:
			runPostModules = explicit
		case PostModuleModePreset:
			runPostModules = explicit && source == "preset"
		}

		if runPostModules {
			if mod := m.GetModule(itemID); mod != nil {
				for _, post := range mod.PostModules {
					resolve(m.normalizeDependencyID(post), false, "")
				}
			}
		}
	}

	// Sort selected modules for consistent order
	var selected []string
	for id := range m.selected {
		selected = append(selected, id)
	}
	sort.Strings(selected)

	for _, id := range selected {
		resolve(id, true, m.selectedSource[id])
	}

	return result
}

// GetCategories returns all categories sorted by order
func (m *Manager) GetCategories() []string {
	var cats []string
	for name := range m.categories {
		cats = append(cats, name)
	}
	sort.Strings(cats)
	return cats
}

// GetCategory returns category info and its modules
func (m *Manager) GetCategory(name string) []*ModuleInfo {
	cat := m.categories[name]
	if cat == nil {
		return []*ModuleInfo{}
	}

	var modules []*ModuleInfo
	seen := make(map[string]bool)

	// Top-level modules
	for _, id := range cat.Modules {
		if seen[id] {
			continue
		}
		if mod := m.GetModule(id); mod != nil {
			seen[id] = true
			modules = append(modules, mod)
		}
	}

	// Include subcategory modules as well (e.g. dev/runtime, ai/agents)
	var subcategoryNames []string
	for subcategoryName := range cat.Subcategories {
		subcategoryNames = append(subcategoryNames, subcategoryName)
	}
	sort.Strings(subcategoryNames)

	for _, subcategoryName := range subcategoryNames {
		subcategory := cat.Subcategories[subcategoryName]
		for _, id := range subcategory.Modules {
			if seen[id] {
				continue
			}
			if mod := m.GetModule(id); mod != nil {
				seen[id] = true
				modules = append(modules, mod)
			}
		}
	}

	return modules
}

// GetAllCategories returns all top-level category names
func (m *Manager) GetAllCategories() []string {
	return m.GetCategories()
}

// GetSelectedModules returns all selected modules
func (m *Manager) GetSelectedModules() []*ModuleInfo {
	var modules []*ModuleInfo
	for id := range m.selected {
		if mod := m.GetModule(id); mod != nil {
			modules = append(modules, mod)
		}
	}
	sort.Slice(modules, func(i, j int) bool {
		return modules[i].Name < modules[j].Name
	})
	return modules
}

// GetSelectedItems returns all selected modules as string IDs
func (m *Manager) GetSelectedItems() []string {
	var items []string
	for id := range m.selected {
		items = append(items, id)
	}
	sort.Strings(items)
	return items
}

// GetContextItems returns UI context items (selected + deselected history)
func (m *Manager) GetContextItems() map[string]bool {
	items := make(map[string]bool, len(m.contextItems))
	for id, selected := range m.contextItems {
		items[id] = selected
	}
	return items
}

// LoadPreset loads modules from a preset JSON file
func (m *Manager) LoadPreset(presetPath string, clearSelection bool) error {
	if clearSelection {
		m.selected = make(map[string]bool)
		m.selectedSource = make(map[string]string)
		m.contextItems = make(map[string]bool)
	}

	data, err := os.ReadFile(presetPath)
	if err != nil {
		return err
	}

	var preset struct {
		Modules []struct {
			ID     string `json:"id"`
			Params *struct {
				Version  string `json:"version"`
				Selected *bool  `json:"selected"`
			} `json:"params"`
		} `json:"modules"`
	}

	if err := json.Unmarshal(data, &preset); err != nil {
		return err
	}

	for _, entry := range preset.Modules {
		if entry.ID == "" {
			continue
		}

		key := m.normalizeSelectionID(entry.ID)

		// Determine if selected - default to true if params not provided or selected not set
		selected := true

		if entry.Params != nil {
			if entry.Params.Version != "" {
				key = entry.ID + ":" + entry.Params.Version
			}
			if entry.Params.Selected != nil {
				selected = *entry.Params.Selected
			}
		}

		m.contextItems[key] = selected
		if selected {
			m.selected[key] = true
			m.selectedSource[key] = "preset"
		} else {
			delete(m.selectedSource, key)
		}
	}

	return nil
}

// SavePreset saves current selection as a preset
func (m *Manager) SavePreset(presetName string) error {
	preset := struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		Modules     []struct {
			ID     string `json:"id"`
			Params struct {
				Version  string `json:"version"`
				Selected bool   `json:"selected"`
			} `json:"params"`
		} `json:"modules"`
	}{
		Name:        presetName,
		Description: "Auto-generated preset",
		Modules:     make([]struct {
			ID     string `json:"id"`
			Params struct {
				Version  string `json:"version"`
				Selected bool   `json:"selected"`
			} `json:"params"`
		}, 0),
	}

	for id := range m.selected {
		parts := strings.Split(id, ":")
		module := struct {
			ID     string `json:"id"`
			Params struct {
				Version  string `json:"version"`
				Selected bool   `json:"selected"`
			} `json:"params"`
		}{
			ID: parts[0],
		}

		if len(parts) > 1 {
			module.Params.Version = parts[1]
		}
		module.Params.Selected = true

		preset.Modules = append(preset.Modules, module)
	}

	presetPath := filepath.Join(m.presetsDir, presetName+".json")
	data, err := json.MarshalIndent(preset, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(presetPath, data, 0644)
}

// Helper function
func contains(slice []string, item string) bool {
	for _, v := range slice {
		if v == item {
			return true
		}
	}
	return false
}
