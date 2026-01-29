import os
import sys
import ctypes
import subprocess
import winreg
from core import logger

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def check_admin():
    if not is_admin():
        logger.error("Administrator privileges are required.")
        logger.warn("Please run this script as Administrator.")
        sys.exit(1)

def expand_env(value):
    return os.path.expandvars(value)

def set_env(name, value, scope="User", dry_run=False):
    """
    Sets a permanent environment variable on Windows.
    Scope: 'User' or 'Machine'
    """
    expanded_value = expand_env(value)
    
    if dry_run:
        logger.dry_run(f"Set Env: {name} = {expanded_value} [{scope}]")
        return

    try:
        if scope == "User":
            key_path = r"Environment"
            hkey = winreg.HKEY_CURRENT_USER
        elif scope == "Machine":
            key_path = r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            hkey = winreg.HKEY_LOCAL_MACHINE
        else:
            raise ValueError(f"Invalid scope: {scope}")

        # Update Registry
        with winreg.OpenKey(hkey, key_path, 0, winreg.KEY_SET_VALUE) as key:
            winreg.SetValueEx(key, name, 0, winreg.REG_EXPAND_SZ, expanded_value)
        
        # Notify system of change
        import win32gui
        import win32con
        # This requires pywin32, which might not be installed. 
        # Fallback to pure ctypes or just warn user to restart shell.
        # using ctypes to broadcast WM_SETTINGCHANGE
        SendMessage = ctypes.windll.user32.SendMessageW
        HWND_BROADCAST = 0xFFFF
        WM_SETTINGCHANGE = 0x001A
        SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, "Environment")

        # Update current process
        os.environ[name] = expanded_value
        logger.success(f"Set Env: {name} = {expanded_value} [{scope}]")
        
    except Exception as e:
        logger.error(f"Failed to set environment variable {name}: {e}")

def add_to_path(new_path, scope="User", dry_run=False):
    expanded_path = expand_env(new_path)
    
    # Check if path exists
    if not os.path.exists(expanded_path) and not dry_run:
        logger.warn(f"Path does not exist: {expanded_path}")
    
    if dry_run:
        logger.dry_run(f"Add to PATH: {expanded_path} [{scope}]")
        return

    try:
        if scope == "User":
            key_path = r"Environment"
            hkey = winreg.HKEY_CURRENT_USER
        else:
            key_path = r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
            hkey = winreg.HKEY_LOCAL_MACHINE

        with winreg.OpenKey(hkey, key_path, 0, winreg.KEY_READ | winreg.KEY_SET_VALUE) as key:
            try:
                current_path, _ = winreg.QueryValueEx(key, "Path")
            except FileNotFoundError:
                current_path = ""

            path_parts = [p for p in current_path.split(";") if p]
            
            # Check for duplicates
            if any(os.path.normpath(p).lower() == os.path.normpath(expanded_path).lower() for p in path_parts):
                logger.info(f"Already in PATH: {expanded_path}")
                return

            new_full_path = current_path + ";" + expanded_path if current_path else expanded_path
            winreg.SetValueEx(key, "Path", 0, winreg.REG_EXPAND_SZ, new_full_path)

        # Notify
        SendMessage = ctypes.windll.user32.SendMessageW
        HWND_BROADCAST = 0xFFFF
        WM_SETTINGCHANGE = 0x001A
        SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, "Environment")
        
        # Update current process
        os.environ["PATH"] += os.pathsep + expanded_path
        logger.success(f"Added to PATH: {expanded_path} [{scope}]")

    except Exception as e:
        logger.error(f"Failed to add to PATH: {e}")
