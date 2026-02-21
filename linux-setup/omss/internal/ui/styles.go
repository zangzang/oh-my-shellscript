package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// Styles holds all UI styling
var (
	headerStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("10")).
			Bold(true).
			Padding(1, 0)

	selectedStyle = lipgloss.NewStyle().
			Background(lipgloss.Color("4")).
			Foreground(lipgloss.Color("15")).
			Padding(0, 1)

	categoryStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("11")).
			Bold(true)

	moduleStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("7"))

	infoBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("4")).
			Padding(0, 1)

	footerStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("8")).
			Padding(0, 1)
)

// FormatHeader formats the header text
func FormatHeader(text string) string {
	return headerStyle.Render(text)
}

// FormatSelected formats selected item
func FormatSelected(text string) string {
	return selectedStyle.Render(text)
}

// FormatCategory formats category text
func FormatCategory(text string) string {
	return categoryStyle.Render(text)
}

// FormatModule formats module text
func FormatModule(text string) string {
	return moduleStyle.Render(text)
}

// FormatInfoBox formats info box
func FormatInfoBox(title, content string) string {
	info := fmt.Sprintf("%s\n%s\n", title, content)
	return infoBoxStyle.Render(info)
}

// FormatFooter formats footer text
func FormatFooter(text string) string {
	return footerStyle.Render(text)
}

// TruncateString truncates string to width
func TruncateString(s string, width int) string {
	if len(s) <= width {
		return s
	}
	return s[:width-3] + "..."
}

// PadRight pads string with spaces on the right
func PadRight(s string, width int) string {
	if len(s) >= width {
		return s[:width]
	}
	return s + strings.Repeat(" ", width-len(s))
}
