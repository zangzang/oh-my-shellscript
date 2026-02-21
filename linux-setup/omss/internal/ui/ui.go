package ui

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/zangzang/oh-my-shellscript/internal/module"
)

type TreeItem struct {
	ID         string
	Label      string
	ItemType   string // preset, separator, category, module
	PresetPath string
	Indent     int
	Selectable bool
}

type RightRow struct {
	ID         string
	BaseID     string
	Label      string
	RowType    string // module-header, module, variant
	Selectable bool
}

type Model struct {
	manager    *module.Manager
	presetsDir string

	width  int
	height int

	focusLeft bool

	allItems      []TreeItem
	filteredItems []TreeItem
	leftCursor    int
	leftScroll    int

	rightRows   []RightRow
	rightCursor int
	rightScroll int

	searchInput textinput.Model
	inSearch    bool

	status string

	executeRequested bool
}

func NewModel(mgr *module.Manager, presetsDir string) *Model {
	si := textinput.New()
	si.Placeholder = "Search modules..."
	si.CharLimit = 64

	m := &Model{
		manager:     mgr,
		presetsDir:  presetsDir,
		focusLeft:   true,
		searchInput: si,
		status:      "Ready",
	}

	m.rebuildTree()
	m.refreshRightPanel()
	return m
}

func (m *Model) Init() tea.Cmd {
	return nil
}

func (m *Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.ensureBounds()
		return m, nil

	case tea.KeyMsg:
		if m.inSearch {
			return m.handleSearchKeys(msg)
		}
		return m.handleNormalKeys(msg)
	}

	return m, nil
}

func (m *Model) handleSearchKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "esc":
		m.inSearch = false
		m.searchInput.Blur()
		m.searchInput.SetValue("")
		m.filteredItems = m.allItems
		m.leftCursor = 0
		m.leftScroll = 0
		m.status = "Search cleared"
		m.ensureBounds()
		return m, nil
	case "enter":
		m.inSearch = false
		m.searchInput.Blur()
		m.status = fmt.Sprintf("Search applied: %d items", len(m.filteredItems))
		return m, nil
	}

	var cmd tea.Cmd
	m.searchInput, cmd = m.searchInput.Update(msg)
	m.applyFilter(m.searchInput.Value())
	m.ensureBounds()
	return m, cmd
}

func (m *Model) handleNormalKeys(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		m.executeRequested = false
		return m, tea.Quit
	case "f5", "r":
		if len(m.manager.GetSelectedItems()) == 0 {
			m.status = "No modules selected"
			return m, nil
		}
		m.executeRequested = true
		m.status = "Run requested"
		return m, tea.Quit
	case "tab":
		m.focusLeft = !m.focusLeft
		m.ensureBounds()
		return m, nil
	case "/":
		m.inSearch = true
		m.searchInput.Focus()
		m.status = "Search mode"
		return m, nil
	case "up", "k":
		if m.focusLeft {
			if m.leftCursor > 0 {
				m.leftCursor--
			}
		} else {
			if m.rightCursor > 0 {
				m.rightCursor--
			}
		}
		m.ensureBounds()
		return m, nil
	case "down", "j":
		if m.focusLeft {
			if m.leftCursor < len(m.filteredItems)-1 {
				m.leftCursor++
			}
		} else {
			if m.rightCursor < len(m.rightRows)-1 {
				m.rightCursor++
			}
		}
		m.ensureBounds()
		return m, nil
	case "home":
		if m.focusLeft {
			m.leftCursor = 0
		} else {
			m.rightCursor = 0
		}
		m.ensureBounds()
		return m, nil
	case "end":
		if m.focusLeft {
			if len(m.filteredItems) > 0 {
				m.leftCursor = len(m.filteredItems) - 1
			}
		} else {
			if len(m.rightRows) > 0 {
				m.rightCursor = len(m.rightRows) - 1
			}
		}
		m.ensureBounds()
		return m, nil
	case "space", " ":
		if m.focusLeft {
			m.activateLeftItem()
		} else {
			m.toggleRightSelection()
		}
		m.ensureBounds()
		return m, nil
	case "enter":
		// Keep Enter non-destructive in list panels.
		return m, nil
	case "backspace", "delete":
		if !m.focusLeft {
			m.deselectRightSelection()
			m.ensureBounds()
		}
		return m, nil
	}

	return m, nil
}

func (m *Model) activateLeftItem() {
	if m.leftCursor < 0 || m.leftCursor >= len(m.filteredItems) {
		return
	}

	item := m.filteredItems[m.leftCursor]
	if !item.Selectable {
		return
	}

	switch item.ItemType {
	case "preset":
		if err := m.manager.LoadPreset(item.PresetPath, false); err != nil {
			m.status = fmt.Sprintf("Preset load failed: %v", err)
			return
		}
		m.status = fmt.Sprintf("Preset loaded: %s", item.Label)
	case "module", "variant":
		m.manager.Toggle(item.ID)
		if m.manager.IsSelected(item.ID) {
			m.status = fmt.Sprintf("Selected: %s", item.Label)
		} else {
			m.status = fmt.Sprintf("Deselected: %s", item.Label)
		}
	default:
		return
	}

	query := ""
	if m.inSearch {
		query = m.searchInput.Value()
	}
	m.rebuildTree()
	m.applyFilter(query)
	m.refreshRightPanel()
}

func (m *Model) toggleRightSelection() {
	if m.rightCursor < 0 || m.rightCursor >= len(m.rightRows) {
		return
	}
	row := m.rightRows[m.rightCursor]
	if !row.Selectable {
		m.status = "Select a module/variant row"
		return
	}

	m.manager.Toggle(row.ID)
	if m.manager.IsSelected(row.ID) {
		m.status = fmt.Sprintf("Selected: %s", row.Label)
	} else {
		m.status = fmt.Sprintf("Deselected: %s", row.Label)
	}

	query := ""
	if m.inSearch {
		query = m.searchInput.Value()
	}
	m.rebuildTree()
	m.applyFilter(query)
	m.refreshRightPanel()
}

func (m *Model) deselectRightSelection() {
	if m.rightCursor < 0 || m.rightCursor >= len(m.rightRows) {
		return
	}
	row := m.rightRows[m.rightCursor]
	if !row.Selectable {
		m.status = "Select a module/variant row"
		return
	}

	if m.manager.IsSelected(row.ID) {
		m.manager.Toggle(row.ID)
		m.status = fmt.Sprintf("Deselected: %s", row.Label)
	} else {
		m.status = fmt.Sprintf("Already deselected: %s", row.Label)
	}

	query := ""
	if m.inSearch {
		query = m.searchInput.Value()
	}
	m.rebuildTree()
	m.applyFilter(query)
	m.refreshRightPanel()
}

func (m *Model) rebuildTree() {
	items := make([]TreeItem, 0, 256)

	presets := m.loadPresets()
	for _, preset := range presets {
		items = append(items, TreeItem{
			ID:         preset,
			Label:      preset,
			ItemType:   "preset",
			PresetPath: filepath.Join(m.presetsDir, preset+".json"),
			Indent:     0,
			Selectable: true,
		})
	}

	if len(presets) > 0 {
		items = append(items, TreeItem{
			ID:         "__sep__",
			Label:      strings.Repeat("-", 18),
			ItemType:   "separator",
			Selectable: false,
		})
	}

	categories := m.manager.GetAllCategories()
	sort.Strings(categories)

	for _, category := range categories {
		items = append(items, TreeItem{
			ID:         "cat:" + category,
			Label:      category,
			ItemType:   "category",
			Indent:     0,
			Selectable: false,
		})

		modules := m.manager.GetCategory(category)
		sort.Slice(modules, func(i, j int) bool {
			return strings.ToLower(modules[i].Name) < strings.ToLower(modules[j].Name)
		})

		for _, mod := range modules {
			items = append(items, TreeItem{
				ID:         mod.ID,
				Label:      mod.Name,
				ItemType:   "module",
				Indent:     1,
				Selectable: true,
			})
		}
	}

	m.allItems = items
	if !m.inSearch || strings.TrimSpace(m.searchInput.Value()) == "" {
		m.filteredItems = m.allItems
	}
}

func (m *Model) loadPresets() []string {
	entries, err := os.ReadDir(m.presetsDir)
	if err != nil {
		return []string{}
	}

	presets := make([]string, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}
		presets = append(presets, strings.TrimSuffix(entry.Name(), ".json"))
	}
	sort.Strings(presets)
	return presets
}

func (m *Model) applyFilter(query string) {
	q := strings.ToLower(strings.TrimSpace(query))
	if q == "" {
		m.filteredItems = m.allItems
		if m.leftCursor >= len(m.filteredItems) {
			m.leftCursor = len(m.filteredItems) - 1
		}
		if m.leftCursor < 0 {
			m.leftCursor = 0
		}
		if m.leftScroll > m.leftCursor {
			m.leftScroll = m.leftCursor
		}
		if m.leftScroll < 0 {
			m.leftScroll = 0
		}
		return
	}

	res := make([]TreeItem, 0, len(m.allItems))
	for _, item := range m.allItems {
		switch item.ItemType {
		case "separator":
			continue
		case "category", "preset":
			if strings.Contains(strings.ToLower(item.Label), q) {
				res = append(res, item)
			}
		case "module":
			if strings.Contains(strings.ToLower(item.Label), q) || strings.Contains(strings.ToLower(item.ID), q) {
				res = append(res, item)
			}
		}
	}

	m.filteredItems = res
	if m.leftCursor >= len(m.filteredItems) {
		m.leftCursor = len(m.filteredItems) - 1
	}
	if m.leftCursor < 0 {
		m.leftCursor = 0
	}
}

func (m *Model) refreshRightPanel() {
	context := m.manager.GetContextItems()

	baseIDs := make(map[string]bool)
	for id := range context {
		baseID := strings.SplitN(id, ":", 2)[0]
		baseIDs[baseID] = true
	}

	var modules []*module.ModuleInfo
	for baseID := range baseIDs {
		if mod := m.manager.GetModule(baseID); mod != nil {
			modules = append(modules, mod)
		}
	}
	sort.Slice(modules, func(i, j int) bool {
		return strings.ToLower(modules[i].Name) < strings.ToLower(modules[j].Name)
	})

	m.rightRows = m.rightRows[:0]
	for _, mod := range modules {
		if len(mod.Variants) > 0 {
			m.rightRows = append(m.rightRows, RightRow{
				ID:         mod.ID,
				BaseID:     mod.ID,
				Label:      mod.Name,
				RowType:    "module-header",
				Selectable: false,
			})
			for _, variant := range mod.Variants {
				variantID := mod.ID + ":" + variant
				m.rightRows = append(m.rightRows, RightRow{
					ID:         variantID,
					BaseID:     mod.ID,
					Label:      variant,
					RowType:    "variant",
					Selectable: true,
				})
			}
		} else {
			m.rightRows = append(m.rightRows, RightRow{
				ID:         mod.ID,
				BaseID:     mod.ID,
				Label:      mod.Name,
				RowType:    "module",
				Selectable: true,
			})
		}
	}

	if m.rightCursor >= len(m.rightRows) {
		m.rightCursor = len(m.rightRows) - 1
	}
	if m.rightCursor < 0 {
		m.rightCursor = 0
	}
}

func (m *Model) View() string {
	if m.width <= 0 || m.height <= 0 {
		return "Loading..."
	}

	headerHeight := 2
	footerHeight := 2
	contentHeight := m.height - headerHeight - footerHeight
	if contentHeight < 4 {
		contentHeight = 4
	}

	usable := m.width - 3
	if usable < 20 {
		usable = 20
	}
	leftWidth := usable / 2
	rightWidth := usable - leftWidth
	if leftWidth < 10 {
		leftWidth = 10
	}
	if rightWidth < 10 {
		rightWidth = 10
	}

	left := m.renderLeftPanel(leftWidth, contentHeight)
	right := m.renderRightPanel(rightWidth, contentHeight)

	leftLines := strings.Split(left, "\n")
	rightLines := strings.Split(right, "\n")

	maxLines := len(leftLines)
	if len(rightLines) > maxLines {
		maxLines = len(rightLines)
	}

	joined := make([]string, 0, maxLines+2)
	joined = append(joined, m.renderHeader())
	for i := 0; i < maxLines; i++ {
		l := ""
		r := ""
		if i < len(leftLines) {
			l = fit(leftLines[i], leftWidth)
		}
		if i < len(rightLines) {
			r = fit(rightLines[i], rightWidth)
		}
		joined = append(joined, l+" | "+r)
	}
	joined = append(joined, m.renderFooter())

	return strings.Join(joined, "\n")
}

func (m *Model) renderHeader() string {
	leftFocus := " "
	rightFocus := " "
	if m.focusLeft {
		leftFocus = "*"
	} else {
		rightFocus = "*"
	}
	search := ""
	if m.inSearch {
		search = " | SEARCH: " + m.searchInput.Value()
	}
	return fmt.Sprintf("%s ITEMS%s | %s SELECTED", leftFocus, search, rightFocus)
}

func (m *Model) renderFooter() string {
	help := "jk/↑↓ Move | Tab Panel | Space: Toggle | Del: Off(right) | / Search | F5/r Run | q Quit"
	if m.status != "" {
		return fit(m.status+" | "+help, m.width)
	}
	return fit(help, m.width)
}

func (m *Model) renderLeftPanel(width, height int) string {
	lines := make([]string, 0, height)
	lines = append(lines, "Available")
	lines = append(lines, strings.Repeat("-", width))

	rows := height - 2
	if rows < 1 {
		rows = 1
	}

	m.leftScroll = normalizeScroll(m.leftCursor, m.leftScroll, rows)
	start := m.leftScroll
	end := start + rows
	if end > len(m.filteredItems) {
		end = len(m.filteredItems)
	}

	for i := start; i < end; i++ {
		item := m.filteredItems[i]
		line := m.formatLeftItem(item)
		line = fit(line, width)

		if i == m.leftCursor {
			line = "> " + line
		} else {
			line = "  " + line
		}
		lines = append(lines, line)
	}

	for len(lines) < height {
		lines = append(lines, strings.Repeat(" ", width))
	}

	return strings.Join(lines, "\n")
}

func (m *Model) formatLeftItem(item TreeItem) string {
	indent := strings.Repeat("  ", item.Indent)
	switch item.ItemType {
	case "preset":
		return indent + "[P] " + item.Label
	case "category":
		return indent + "[C] " + item.Label
	case "separator":
		return indent + item.Label
	case "module":
		mark := "[ ]"
		if m.manager.IsSelected(item.ID) {
			mark = "[X]"
		}
		return indent + mark + " " + item.Label
	default:
		return indent + item.Label
	}
}

func (m *Model) renderRightPanel(width, height int) string {
	lines := make([]string, 0, height)
	selectedHeight := (height * 55) / 100
	if selectedHeight < 6 {
		selectedHeight = 6
	}
	if selectedHeight > height-4 {
		selectedHeight = height - 4
	}
	infoHeight := height - selectedHeight
	if infoHeight < 4 {
		infoHeight = 4
		selectedHeight = height - infoHeight
	}

	// Top: selected list
	lines = append(lines, "Selected")
	lines = append(lines, strings.Repeat("-", width))

	rows := selectedHeight - 2
	if rows < 1 {
		rows = 1
	}

	m.rightScroll = normalizeScroll(m.rightCursor, m.rightScroll, rows)
	start := m.rightScroll
	end := start + rows
	if end > len(m.rightRows) {
		end = len(m.rightRows)
	}

	if len(m.rightRows) == 0 {
		lines = append(lines, fit("(none)", width))
	} else {
		for i := start; i < end; i++ {
			row := m.rightRows[i]
			line := m.formatRightRow(row)
			line = fit(line, width)
			if i == m.rightCursor {
				line = "> " + line
			} else {
				line = "  " + line
			}
			lines = append(lines, line)
		}
	}
	for len(lines) < selectedHeight {
		lines = append(lines, strings.Repeat(" ", width))
	}

	// Bottom: info panel
	lines = append(lines, "Info")
	lines = append(lines, strings.Repeat("-", width))
	infoLines := m.currentInfoLines(width, infoHeight-2)
	for _, line := range infoLines {
		lines = append(lines, fit(line, width))
	}
	for len(lines) < height {
		lines = append(lines, strings.Repeat(" ", width))
	}

	return strings.Join(lines, "\n")
}

func (m *Model) currentInfoLines(width int, maxLines int) []string {
	if maxLines <= 0 {
		return []string{}
	}

	if m.focusLeft {
		if len(m.filteredItems) == 0 || m.leftCursor < 0 || m.leftCursor >= len(m.filteredItems) {
			return []string{"No item"}
		}

		item := m.filteredItems[m.leftCursor]
		switch item.ItemType {
		case "module":
			return m.moduleInfoLines(item.ID, maxLines)
		case "preset":
			return m.presetInfoLines(item.PresetPath, item.Label, maxLines)
		case "category":
			return trimLines([]string{
				"Category",
				"- " + item.Label,
				"",
				"Move to module and press Space to toggle.",
			}, maxLines)
		default:
			return []string{""}
		}
	}

	if len(m.rightRows) == 0 || m.rightCursor < 0 || m.rightCursor >= len(m.rightRows) {
		return []string{"No selection"}
	}
	row := m.rightRows[m.rightCursor]
	if row.RowType == "variant" {
		return m.moduleInfoLines(row.ID, maxLines)
	}
	return m.moduleInfoLines(row.BaseID, maxLines)
}

func (m *Model) moduleInfoLines(id string, maxLines int) []string {
	mod := m.manager.GetModule(id)
	if mod == nil {
		return []string{"Module not found", id}
	}

	selected := "No"
	if m.manager.IsSelected(id) {
		selected = "Yes"
	}

	lines := []string{
		mod.Name,
		"ID: " + id,
		"Category: " + mod.Category,
		"Selected: " + selected,
	}

	if strings.Contains(id, ":") {
		parts := strings.SplitN(id, ":", 2)
		if len(parts) == 2 && parts[1] != "" {
			lines = append(lines, "Current Variant: "+parts[1])
		}
	}

	if len(mod.Variants) > 0 {
		lines = append(lines, "")
		lines = append(lines, "Variant Options:")
		for _, variant := range mod.Variants {
			variantID := mod.ID + ":" + variant
			mark := "[ ]"
			if m.manager.IsSelected(variantID) {
				mark = "[X]"
			}
			lines = append(lines, fmt.Sprintf("- %s %s", mark, variant))
		}
	}

	if len(mod.Requires) > 0 {
		lines = append(lines, "Requires: "+strings.Join(mod.Requires, ", "))
	}

	if mod.Description != "" {
		lines = append(lines, "")
		desc := strings.ReplaceAll(mod.Description, "\n", " ")
		lines = append(lines, "Desc: "+desc)
	}

	return trimLines(lines, maxLines)
}

func (m *Model) presetInfoLines(path, fallbackName string, maxLines int) []string {
	type presetModule struct {
		ID string `json:"id"`
	}
	type presetData struct {
		Name        string         `json:"name"`
		Description string         `json:"description"`
		Modules     []presetModule `json:"modules"`
	}

	lines := []string{"Preset", "- " + fallbackName}

	data, err := os.ReadFile(path)
	if err != nil {
		lines = append(lines, "")
		lines = append(lines, "Cannot read preset file")
		return trimLines(lines, maxLines)
	}

	var preset presetData
	if err := json.Unmarshal(data, &preset); err != nil {
		lines = append(lines, "")
		lines = append(lines, "Invalid preset format")
		return trimLines(lines, maxLines)
	}

	if preset.Name != "" {
		lines[1] = "- " + preset.Name
	}
	lines = append(lines, fmt.Sprintf("Modules: %d", len(preset.Modules)))
	if preset.Description != "" {
		lines = append(lines, "")
		lines = append(lines, "Desc: "+strings.ReplaceAll(preset.Description, "\n", " "))
	}
	return trimLines(lines, maxLines)
}

func trimLines(lines []string, maxLines int) []string {
	if maxLines <= 0 {
		return []string{}
	}
	if len(lines) <= maxLines {
		return lines
	}
	trimmed := append([]string{}, lines[:maxLines]...)
	if maxLines > 0 {
		trimmed[maxLines-1] = "..."
	}
	return trimmed
}

func (m *Model) ensureBounds() {
	if m.leftCursor >= len(m.filteredItems) {
		m.leftCursor = len(m.filteredItems) - 1
	}
	if m.leftCursor < 0 {
		m.leftCursor = 0
	}

	if m.rightCursor >= len(m.rightRows) {
		m.rightCursor = len(m.rightRows) - 1
	}
	if m.rightCursor < 0 {
		m.rightCursor = 0
	}
}

func (m *Model) formatRightRow(row RightRow) string {
	switch row.RowType {
	case "module-header":
		return "[M] " + row.Label
	case "variant":
		mark := "[ ]"
		if m.manager.IsSelected(row.ID) {
			mark = "[X]"
		}
		return "  " + mark + " " + row.Label
	case "module":
		mark := "[ ]"
		if m.manager.IsSelected(row.ID) {
			mark = "[X]"
		}
		return mark + " " + row.Label
	default:
		return row.Label
	}
}

func normalizeScroll(cursor, scroll, rows int) int {
	if rows <= 0 {
		return 0
	}
	if cursor < scroll {
		scroll = cursor
	}
	if cursor >= scroll+rows {
		scroll = cursor - rows + 1
	}
	if scroll < 0 {
		scroll = 0
	}
	return scroll
}

func fit(s string, width int) string {
	if width <= 0 {
		return ""
	}
	if len(s) > width {
		if width <= 1 {
			return s[:width]
		}
		return s[:width-1] + "~"
	}
	if len(s) < width {
		return s + strings.Repeat(" ", width-len(s))
	}
	return s
}

func (m *Model) GetInstallList() []string {
	return m.manager.ResolveDependencies()
}

func (m *Model) GetSelectedItems() []string {
	return m.manager.GetSelectedItems()
}

func (m *Model) ShouldRunInstall() bool {
	return m.executeRequested
}
