#!/usr/bin/env python3
"""
Linux Setup Assistant v4.0 - Python TUI (textual)
빠르고 직관적인 모듈 선택 인터페이스
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

# textual 설치 확인
try:
    from textual.app import App, ComposeResult
    from textual.widgets import Tree, Static, Footer, Header, Button, Label, ListView, ListItem
    from textual.containers import Horizontal, Vertical, Container
    from textual.binding import Binding
    from textual import events
except ImportError:
    print("textual 라이브러리가 필요합니다. 설치 중...")
    subprocess.run([sys.executable, "-m", "pip", "install", "textual", "-q"])
    from textual.app import App, ComposeResult
    from textual.widgets import Tree, Static, Footer, Header, Button, Label, ListView, ListItem
    from textual.containers import Horizontal, Vertical, Container
    from textual.binding import Binding
    from textual import events


SCRIPT_DIR = Path(__file__).parent.resolve()
MODULES_DIR = SCRIPT_DIR / "modules"
PRESETS_DIR = SCRIPT_DIR / "presets"
CONFIG_DIR = SCRIPT_DIR / "config"


class ModuleInfo:
    """모듈 정보 클래스"""
    def __init__(self, path: Path):
        self.path = path
        self.meta_file = path / "meta.json"
        self._meta = None
    
    @property
    def meta(self) -> dict:
        if self._meta is None:
            if self.meta_file.exists():
                self._meta = json.loads(self.meta_file.read_text())
            else:
                self._meta = {}
        return self._meta
    
    @property
    def id(self) -> str:
        return self.meta.get("id", "")
    
    @property
    def name(self) -> str:
        return self.meta.get("name", self.path.name)
    
    @property
    def description(self) -> str:
        return self.meta.get("description", "")
    
    @property
    def requires(self) -> list:
        return self.meta.get("requires", [])
    
    @property
    def variants(self) -> list:
        return self.meta.get("variants", [])


class ModuleManager:
    """모듈 관리자"""
    def __init__(self):
        self.modules: dict[str, ModuleInfo] = {}
        self.categories: dict = {}
        self.selected: set[str] = set()
        self._load_modules()
        self._load_categories()
    
    def _load_modules(self):
        """모든 모듈 로드"""
        for meta_file in MODULES_DIR.rglob("meta.json"):
            mod = ModuleInfo(meta_file.parent)
            if mod.id:
                self.modules[mod.id] = mod
                # 폴더명으로도 접근 가능하게
                self.modules[meta_file.parent.name] = mod
    
    def _load_categories(self):
        """카테고리 설정 로드"""
        cat_file = CONFIG_DIR / "categories.json"
        if cat_file.exists():
            self.categories = json.loads(cat_file.read_text())
    
    def get_module(self, mod_id: str) -> Optional[ModuleInfo]:
        """모듈 ID 또는 폴더명으로 모듈 찾기"""
        # 직접 매치
        if mod_id in self.modules:
            return self.modules[mod_id]
        # variant 분리 (dev.java:17 -> dev.java)
        base_id = mod_id.split(":")[0]
        return self.modules.get(base_id)
    
    def toggle(self, item_id: str):
        """선택 토글"""
        if item_id in self.selected:
            self.selected.discard(item_id)
        else:
            self.selected.add(item_id)
    
    def resolve_dependencies(self) -> list[str]:
        """의존성 해결하여 설치 순서 반환"""
        result = []
        visited = set()
        
        def resolve(item_id: str):
            if item_id in visited:
                return
            visited.add(item_id)
            
            mod = self.get_module(item_id)
            if mod:
                for dep in mod.requires:
                    resolve(dep)
            
            result.append(item_id)
        
        for item in sorted(self.selected):
            resolve(item)
        
        return result
    
    def load_preset(self, preset_file: Path):
        """프리셋 로드"""
        self.selected.clear()
        if preset_file.exists():
            data = json.loads(preset_file.read_text())
            for entry in data.get("modules", []):
                mod_id = entry.get("id", "")
                version = entry.get("params", {}).get("version", "")
                selected = entry.get("params", {}).get("selected", True)
                
                if selected:
                    key = f"{mod_id}:{version}" if version else mod_id
                    self.selected.add(key)


class SelectedList(ListView):
    """선택된 항목 리스트 (제거 가능)"""
    
    BINDINGS = [
        Binding("space", "remove_item", "제거", show=True),
        Binding("delete", "remove_item", "제거", show=False),
        Binding("backspace", "remove_item", "제거", show=False),
    ]
    
    def __init__(self, manager: ModuleManager):
        super().__init__()
        self.manager = manager
    
    def refresh_list(self):
        """리스트 새로고침"""
        self.clear()
        for item in sorted(self.manager.selected):
            list_item = ListItem(Label(f"[green]✓[/] {item}"))
            list_item.data = item  # 데이터 저장
            self.append(list_item)
    
    def action_remove_item(self):
        """선택된 항목 제거"""
        if self.highlighted_child:
            item_id = getattr(self.highlighted_child, 'data', None)
            if item_id:
                self.manager.selected.discard(item_id)
                self.refresh_list()
                # 트리도 업데이트
                try:
                    tree = self.app.query_one(ModuleTree)
                    tree.refresh_all_labels()
                except Exception:
                    pass


class InfoPanel(Static):
    """모듈 정보 패널"""
    
    def __init__(self, manager: ModuleManager):
        super().__init__("")
        self.manager = manager
        self.current_id = ""
    
    def update_info(self, mod_id: str = ""):
        """모듈 정보 업데이트"""
        self.current_id = mod_id
        lines = []
        
        if mod_id:
            mod = self.manager.get_module(mod_id)
            if mod:
                lines.append(f"[bold]{mod.name}[/]")
                if mod.description:
                    lines.append(f"[dim]{mod.description}[/]")
                if mod.requires:
                    lines.append("")
                    lines.append("[yellow]의존성:[/]")
                    for dep in mod.requires:
                        lines.append(f"  ↳ {dep}")
                if mod.variants:
                    lines.append("")
                    lines.append(f"[cyan]버전:[/] {', '.join(mod.variants)}")
        else:
            lines.append("[dim]모듈을 선택하세요[/]")
        
        self.update("\n".join(lines))


class ModuleTree(Tree):
    """모듈 트리 위젯"""
    
    BINDINGS = [
        Binding("space", "toggle_select", "선택", show=True),
    ]
    
    def __init__(self, manager: ModuleManager):
        super().__init__("🐧 Modules")
        self.manager = manager
        self.node_map: dict[str, str] = {}  # node_id -> module_id
    
    def on_mount(self):
        """트리 구성"""
        self.root.expand()
        self._build_tree()
    
    def _build_tree(self):
        """카테고리 기반 트리 구성"""
        categories = self.manager.categories
        
        # 카테고리 순서대로
        sorted_cats = sorted(
            categories.items(),
            key=lambda x: x[1].get("order", 99)
        )
        
        for cat_key, cat_data in sorted_cats:
            cat_name = cat_data.get("name", cat_key)
            cat_node = self.root.add(cat_name, expand=True)
            
            # 서브카테고리
            if "subcategories" in cat_data:
                for sub_key, sub_data in cat_data["subcategories"].items():
                    sub_name = sub_data.get("name", sub_key)
                    sub_node = cat_node.add(sub_name, expand=True)
                    
                    for mod_folder in sub_data.get("modules", []):
                        self._add_module_nodes(sub_node, mod_folder)
            
            # 직접 모듈
            for mod_folder in cat_data.get("modules", []):
                self._add_module_nodes(cat_node, mod_folder)
    
    def _add_module_nodes(self, parent_node, mod_folder: str):
        """모듈 노드 추가"""
        mod = self.manager.modules.get(mod_folder)
        if not mod:
            return
        
        if mod.variants:
            # variants가 있으면 항상 서브트리로 그룹화
            mod_node = parent_node.add(f"📦 {mod.name}", expand=False)
            for v in mod.variants:
                key = f"{mod.id}:{v}"
                mark = "☑" if key in self.manager.selected else "☐"
                label = f"{mark} {v}"
                node = mod_node.add_leaf(label)
                self.node_map[str(node._id)] = key
        else:
            key = mod.id
            mark = "☑" if key in self.manager.selected else "☐"
            label = f"{mark} {mod.name}"
            node = parent_node.add_leaf(label)
            self.node_map[str(node._id)] = key
    
    def action_toggle_select(self):
        """스페이스로 선택 토글"""
        node = self.cursor_node
        if node and str(node._id) in self.node_map:
            mod_id = self.node_map[str(node._id)]
            self.manager.toggle(mod_id)
            self._update_node_label(node, mod_id)
            # 선택 리스트 업데이트
            try:
                selected_list = self.app.query_one(SelectedList)
                selected_list.refresh_list()
            except Exception:
                pass
    
    def _update_node_label(self, node, mod_id: str):
        """노드 라벨 업데이트"""
        mod = self.manager.get_module(mod_id)
        if mod:
            mark = "☑" if mod_id in self.manager.selected else "☐"
            if ":" in mod_id:
                version = mod_id.split(":")[1]
                # variants 있는 모듈은 버전만 표시
                node.set_label(f"{mark} {version}")
            else:
                node.set_label(f"{mark} {mod.name}")
    
    def on_tree_node_selected(self, event: Tree.NodeSelected):
        """노드 선택 시 정보 표시"""
        self._show_node_info(event.node)
    
    def on_tree_node_highlighted(self, event: Tree.NodeHighlighted):
        """노드 커서 이동 시 정보 표시"""
        self._show_node_info(event.node)
    
    def _show_node_info(self, node):
        """노드 정보 표시"""
        if str(node._id) in self.node_map:
            mod_id = self.node_map[str(node._id)]
            try:
                info = self.app.query_one(InfoPanel)
                info.update_info(mod_id)
            except Exception:
                pass
    
    def refresh_all_labels(self):
        """모든 노드 라벨 새로고침"""
        for node_id, mod_id in self.node_map.items():
            # 노드 찾아서 업데이트
            for node in self.root.children:
                self._refresh_node_recursive(node, mod_id)
    
    def _refresh_node_recursive(self, node, target_mod_id: str):
        """재귀적으로 노드 업데이트"""
        node_id_str = str(node._id)
        if node_id_str in self.node_map and self.node_map[node_id_str] == target_mod_id:
            self._update_node_label(node, target_mod_id)
        for child in node.children:
            self._refresh_node_recursive(child, target_mod_id)


class SetupApp(App):
    """메인 애플리케이션"""
    
    CSS = """
    Screen {
        layout: horizontal;
    }
    
    #tree-panel {
        width: 55%;
        border: solid green;
        padding: 1;
    }
    
    #info-panel {
        width: 45%;
        layout: vertical;
    }
    
    #selected-box {
        height: 50%;
        border: solid cyan;
        padding: 1;
    }
    
    #info-box {
        height: 50%;
        border: solid yellow;
        padding: 1;
    }
    
    SelectedList {
        height: 100%;
    }
    
    SelectedList > ListItem {
        padding: 0 1;
    }
    
    SelectedList:focus > ListItem.--highlight {
        background: $accent;
    }
    
    Footer {
        background: $primary-background;
    }
    """
    
    BINDINGS = [
        Binding("q", "quit", "종료"),
        Binding("escape", "quit", "종료", show=False),
        Binding("i", "install", "설치(i)"),
        Binding("p", "load_preset", "프리셋(p)"),
        Binding("d", "dry_run", "시뮬(d)"),
        Binding("s", "save_preset", "저장(s)"),
        Binding("tab", "focus_next", "패널", show=True),
    ]
    
    def __init__(self, preset: str = None, action: str = None):
        super().__init__()
        self.manager = ModuleManager()
        self.preset_arg = preset
        self.action_mode = action
    
    def compose(self) -> ComposeResult:
        yield Header()
        with Horizontal():
            with Container(id="tree-panel"):
                yield ModuleTree(self.manager)
            with Container(id="info-panel"):
                with Container(id="selected-box"):
                    yield Label("[bold cyan]━━━ 선택됨 (Space로 제거) ━━━[/]")
                    yield SelectedList(self.manager)
                with Container(id="info-box"):
                    yield Label("[bold yellow]━━━ 모듈 정보 ━━━[/]")
                    yield InfoPanel(self.manager)
        yield Footer()
    
    def on_mount(self):
        self.title = "🐧 Linux Setup Assistant v4.0"
        self.sub_title = "Space: 선택 | i: 설치 | d: 시뮬 | s: 저장 | q: 종료"
        
        # 프리셋 로드
        if self.preset_arg:
            preset_path = Path(self.preset_arg)
            if not preset_path.exists():
                preset_path = PRESETS_DIR / f"{self.preset_arg}.json"
            if preset_path.exists():
                self.manager.load_preset(preset_path)
                self.notify(f"프리셋 로드: {preset_path.stem}")
                # 선택 리스트 새로고침
                try:
                    self.query_one(SelectedList).refresh_list()
                except Exception:
                    pass
        
        # 액션 모드
        if self.action_mode == "execute":
            self.call_later(self.action_install)
        elif self.action_mode == "dry-run":
            self.call_later(self.action_dry_run)
    
    def action_quit(self):
        """종료"""
        self.exit()
    
    def action_install(self):
        """설치 실행"""
        if not self.manager.selected:
            self.notify("선택된 모듈이 없습니다!", severity="warning")
            return
        
        install_list = self.manager.resolve_dependencies()
        selected_items = list(self.manager.selected)
        self.exit(result=("execute", install_list, selected_items))
    
    def action_dry_run(self):
        """시뮬레이션"""
        if not self.manager.selected:
            self.notify("선택된 모듈이 없습니다!", severity="warning")
            return
        
        install_list = self.manager.resolve_dependencies()
        selected_items = list(self.manager.selected)
        self.exit(result=("dry-run", install_list, selected_items))
    
    def action_save_preset(self):
        """현재 선택을 프리셋으로 저장"""
        if not self.manager.selected:
            self.notify("선택된 모듈이 없습니다!", severity="warning")
            return
        
        selected_items = list(self.manager.selected)
        self.exit(result=("save", [], selected_items))
    
    def action_load_preset(self):
        """프리셋 선택 (간단 버전)"""
        presets = list(PRESETS_DIR.glob("*.json"))
        if presets:
            # 첫 번째 프리셋 로드 (추후 선택 UI 추가)
            self.notify("p를 여러 번 눌러 프리셋 순환")


def save_preset(selected_items: list[str], preset_name: str = None):
    """선택된 항목을 프리셋으로 저장"""
    from datetime import datetime
    
    if not preset_name:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        preset_name = f"custom_{timestamp}"
    
    preset_data = {
        "name": preset_name,
        "description": f"자동 생성된 프리셋 ({datetime.now().strftime('%Y-%m-%d %H:%M')})",
        "modules": []
    }
    
    for item in sorted(selected_items):
        if ":" in item:
            mod_id, version = item.split(":", 1)
            preset_data["modules"].append({
                "id": mod_id,
                "params": {"version": version}
            })
        else:
            preset_data["modules"].append({"id": item})
    
    preset_path = PRESETS_DIR / f"{preset_name}.json"
    preset_path.write_text(json.dumps(preset_data, indent=2, ensure_ascii=False))
    print(f"✅ 프리셋 저장됨: {preset_path}")
    return preset_path


def run_installation(install_list: list[str], selected_items: list[str] = None, dry_run: bool = False):
    """설치 실행"""
    print("\n" + "=" * 50)
    print("📦 설치 순서 (의존성 해결됨)")
    print("=" * 50)
    for i, item in enumerate(install_list, 1):
        print(f"  {i}. {item}")
    print()
    
    if dry_run:
        print("🔍 시뮬레이션 모드 - 실제 설치 없음")
        # 프리셋 저장 제안
        if selected_items:
            try:
                save = input("이 선택을 프리셋으로 저장하시겠습니까? (y/N): ").strip().lower()
                if save == 'y':
                    name = input("프리셋 이름 (Enter=자동): ").strip() or None
                    save_preset(selected_items, name)
            except KeyboardInterrupt:
                print("\n\n⚠️ 취소되었습니다.")
        return
    
    # 프리셋 저장 제안
    if selected_items:
        try:
            save = input("설치 전 이 선택을 프리셋으로 저장하시겠습니까? (y/N): ").strip().lower()
            if save == 'y':
                name = input("프리셋 이름 (Enter=자동): ").strip() or None
                save_preset(selected_items, name)
        except KeyboardInterrupt:
            print("\n\n⚠️ 취소되었습니다.")
            return
    
    print("\n🚀 설치를 시작합니다... (Ctrl+C로 중단 가능)")
    print("-" * 50)
    
    # 실제 설치
    success_count = 0
    fail_count = 0
    cancelled = False
    
    try:
        for item in install_list:
            mod_id = item.split(":")[0]
            variant = item.split(":")[1] if ":" in item else ""
            
            # 모듈 경로 찾기
            found = False
            for meta_file in MODULES_DIR.rglob("meta.json"):
                try:
                    meta = json.loads(meta_file.read_text())
                    if meta.get("id") == mod_id:
                        install_script = meta_file.parent / "install.sh"
                        if install_script.exists():
                            print(f"\n{'='*50}")
                            print(f">>> [{meta.get('name', mod_id)}] 설치 중...")
                            if variant:
                                print(f"    variant: {variant}")
                            print("=" * 50)
                            
                            # 환경변수로 variant 전달
                            env = dict(os.environ)
                            if variant:
                                env["VERSION"] = variant
                                env["VARIANT"] = variant
                            
                            result = subprocess.run(
                                ["bash", str(install_script), variant] if variant else ["bash", str(install_script)],
                                env=env,
                                cwd=meta_file.parent
                            )
                            
                            if result.returncode != 0:
                                print(f"❌ 실패: {mod_id}")
                                fail_count += 1
                            else:
                                print(f"✅ 완료: {mod_id}")
                                success_count += 1
                            found = True
                        break
                except Exception as e:
                    print(f"⚠️ 오류: {e}")
            
            if not found:
                print(f"⚠️ 모듈을 찾을 수 없음: {mod_id}")
                fail_count += 1
                
    except KeyboardInterrupt:
        cancelled = True
        print("\n")
        print("=" * 50)
        print("⚠️ 사용자에 의해 취소되었습니다.")
        print("=" * 50)
    
    if not cancelled:
        print("\n" + "=" * 50)
        print(f"📊 설치 결과: 성공 {success_count}, 실패 {fail_count}")
        print("=" * 50)
    else:
        print(f"📊 중단 시점: 성공 {success_count}, 실패 {fail_count}")


def main():
    import argparse
    import signal
    
    # SIGINT (Ctrl+C) graceful 처리
    def signal_handler(sig, frame):
        print("\n\n⚠️ 취소되었습니다.")
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    
    parser = argparse.ArgumentParser(description="Linux Setup Assistant")
    parser.add_argument("--preset", "-p", help="프리셋 이름 또는 경로")
    parser.add_argument("--execute", "--run", action="store_true", help="바로 실행")
    parser.add_argument("--dry-run", action="store_true", help="시뮬레이션")
    args = parser.parse_args()
    
    action = None
    if args.execute:
        action = "execute"
    elif args.dry_run:
        action = "dry-run"
    
    app = SetupApp(preset=args.preset, action=action)
    result = app.run()
    
    if result:
        mode, install_list, selected_items = result
        
        if mode == "save":
            # 프리셋 저장만
            name = input("프리셋 이름 (Enter=자동): ").strip() or None
            save_preset(selected_items, name)
        elif mode == "execute":
            run_installation(install_list, selected_items, dry_run=False)
        elif mode == "dry-run":
            run_installation(install_list, selected_items, dry_run=True)


if __name__ == "__main__":
    main()
