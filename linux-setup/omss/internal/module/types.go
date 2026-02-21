package module

// ModuleInfo represents a single module's metadata
type ModuleInfo struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Category    string   `json:"category"`
	Requires    []string `json:"requires,omitempty"`
	PostModules []string `json:"post_modules,omitempty"`
	Variants    []string `json:"variants,omitempty"`
	DefaultVariant string `json:"-"`
}

// CategoryInfo represents a category with its modules
type CategoryInfo struct {
	Name            string
	Order           int
	Modules         []string
	Subcategories   map[string]*SubcategoryInfo
}

// SubcategoryInfo represents a subcategory
type SubcategoryInfo struct {
	Name    string
	Modules []string
}

// InstallResult represents the result of an installation
type InstallResult struct {
	ModuleID string
	Success  bool
	Error    string
	Output   string
}
