import sys
import os
import time
import threading
import itertools

# ANSI Colors
CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
MAGENTA = "\033[95m"
GREY = "\033[90m"
WHITE = "\033[97m"
RESET = "\033[0m"
BOLD = "\033[1m"

# Enable ANSI support in Windows console
if os.name == 'nt':
    import ctypes
    kernel32 = ctypes.windll.kernel32
    kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)

def info(msg):
    print(f"{CYAN}INFO:{RESET} {msg}")

def success(msg):
    print(f"{GREEN}SUCCESS:{RESET} {msg}")

def warn(msg):
    print(f"{YELLOW}WARN:{RESET} {msg}")

def error(msg):
    print(f"{RED}ERROR:{RESET} {msg}")

def debug(msg):
    # print(f"{GREY}DEBUG: {msg}{RESET}")
    pass

def section(msg):
    line = "─" * 60
    print(f"\n{CYAN}{line}")
    print(f" {BOLD}{msg}{RESET}")
    print(f"{CYAN}{line}{RESET}\n")

def dry_run(msg):
    print(f"{MAGENTA}🔍 [DRY RUN]{RESET} {msg}")

class Spinner:
    def __init__(self, message="Processing..."):
        self.message = message
        self.stop_running = False
        self.thread = None

    def _spin(self):
        spinner_chars = itertools.cycle(['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'])
        while not self.stop_running:
            sys.stdout.write(f"\r{CYAN}{next(spinner_chars)}{RESET} {self.message}")
            sys.stdout.flush()
            time.sleep(0.1)

    def start(self):
        self.stop_running = False
        self.thread = threading.Thread(target=self._spin)
        self.thread.start()

    def stop(self, success_msg=None):
        self.stop_running = True
        if self.thread:
            self.thread.join()
        sys.stdout.write("\r")
        sys.stdout.flush()
        if success_msg:
            print(f"{GREEN}✔{RESET} {success_msg}" + " " * 20) # Clear line residue
        else:
            print(" " * (len(self.message) + 10) + "\r", end="") # Clear line