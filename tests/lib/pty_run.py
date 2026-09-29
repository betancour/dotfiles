#!/usr/bin/env python3
"""Launch a command in a prepared environment.

Modes:
  pipe  stdin is /dev/null, stdout and stderr are separate
  pty   a real terminal; stdout and stderr share the pty

Prints "<exit_code> <elapsed_ms>" on stdout.
DOTFILES_TEST_UMASK in the env file, if set, is applied to the child and
removed before exec so the shell does not see the harness variable.
"""
from __future__ import annotations

import os
import pty
import select
import signal
import sys
import time


def _set_winsize(fd: int) -> None:
    """Wide pty so a long PATH is one recorded line, not a wrapped one."""
    import fcntl
    import struct
    import termios

    winsize = struct.pack("HHHH", 60, 240, 0, 0)
    try:
        fcntl.ioctl(fd, termios.TIOCSWINSZ, winsize)
    except OSError:
        pass


def _exit_code(status: int) -> int:
    if os.WIFEXITED(status):
        return os.WEXITSTATUS(status)
    if os.WIFSIGNALED(status):
        return 128 + os.WTERMSIG(status)
    return 1


def _load_env(path: str) -> dict[str, str]:
    env: dict[str, str] = {}
    with open(path, encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            key, sep, value = line.partition("=")
            if not sep or not key:
                continue
            env[key] = value
    return env


def _read_flags(argv: list[str]) -> tuple[str, str, str, str, float, list[str]]:
    mode = "pipe"
    capture = ""
    stderr_path = ""
    cwd = ""
    timeout = 25.0
    env_file = ""
    args = argv[1:]
    command: list[str] = []
    i = 0
    while i < len(args):
        item = args[i]
        if item == "--":
            command = args[i + 1 :]
            break
        if item == "--mode":
            mode = args[i + 1]
            i += 2
            continue
        if item == "--capture":
            capture = args[i + 1]
            i += 2
            continue
        if item == "--stderr":
            stderr_path = args[i + 1]
            i += 2
            continue
        if item == "--cwd":
            cwd = args[i + 1]
            i += 2
            continue
        if item == "--env-file":
            env_file = args[i + 1]
            i += 2
            continue
        if item == "--timeout":
            timeout = float(args[i + 1])
            i += 2
            continue
        sys.stderr.write(f"pty_run: unknown argument {item}\n")
        sys.exit(2)
    if mode not in ("pipe", "pty") or not capture or not command or not env_file:
        sys.stderr.write("pty_run: missing required arguments\n")
        sys.exit(2)
    return mode, capture, stderr_path, cwd, timeout, command


def _apply_umask(env: dict[str, str]) -> None:
    raw = env.pop("DOTFILES_TEST_UMASK", "")
    if not raw:
        return
    os.umask(int(raw, 8))


def _run_pipe(command: list[str], env: dict[str, str], cwd: str, timeout: float, capture: str, stderr_path: str) -> tuple[int, float]:
    import subprocess

    _apply_umask(env)
    started = time.perf_counter()
    try:
        proc = subprocess.run(
            command,
            env=env,
            cwd=cwd or None,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        code = proc.returncode
        out = proc.stdout
        err = proc.stderr
    except subprocess.TimeoutExpired as exc:
        code = 124
        out = exc.stdout or b""
        err = (exc.stderr or b"") + b"\n[[TIMEOUT]]\n"
    elapsed = (time.perf_counter() - started) * 1000.0
    with open(capture, "wb") as handle:
        handle.write(out)
    if stderr_path:
        with open(stderr_path, "wb") as handle:
            handle.write(err)
    return code, elapsed


def _run_pty(command: list[str], env: dict[str, str], cwd: str, timeout: float, capture: str) -> tuple[int, float]:
    pid, master = pty.fork()
    if pid == 0:
        try:
            if cwd:
                os.chdir(cwd)
            _apply_umask(env)
            os.execvpe(command[0], command, env)
        except OSError as exc:
            sys.stderr.write(f"{exc}\n")
            os._exit(127)
    _set_winsize(master)
    started = time.perf_counter()
    chunks: list[bytes] = []
    code = 1
    deadline = started + timeout
    try:
        while True:
            remain = deadline - time.perf_counter()
            if remain <= 0:
                os.kill(pid, signal.SIGKILL)
                _, status = os.waitpid(pid, 0)
                code = 124
                chunks.append(b"\n[[TIMEOUT]]\n")
                break
            ready, _, _ = select.select([master], [], [], min(0.1, remain))
            if master in ready:
                try:
                    data = os.read(master, 65536)
                except OSError:
                    data = b""
                if data:
                    chunks.append(data)
                    continue
                _, status = os.waitpid(pid, 0)
                code = _exit_code(status)
                break
            wpid, status = os.waitpid(pid, os.WNOHANG)
            if wpid:
                while True:
                    ready, _, _ = select.select([master], [], [], 0)
                    if not ready:
                        break
                    try:
                        data = os.read(master, 65536)
                    except OSError:
                        data = b""
                    if not data:
                        break
                    chunks.append(data)
                code = _exit_code(status)
                break
    finally:
        try:
            os.close(master)
        except OSError:
            pass
    elapsed = (time.perf_counter() - started) * 1000.0
    with open(capture, "wb") as handle:
        handle.write(b"".join(chunks))
    return code, elapsed


def main() -> None:
    mode, capture, stderr_path, cwd, timeout, command = _read_flags(sys.argv)
    env = _load_env(sys.argv[sys.argv.index("--env-file") + 1])
    if mode == "pipe":
        code, elapsed = _run_pipe(command, env, cwd, timeout, capture, stderr_path)
    else:
        code, elapsed = _run_pty(command, env, cwd, timeout, capture)
        if stderr_path:
            with open(stderr_path, "wb") as handle:
                handle.write(b"")
    sys.stdout.write(f"{code} {elapsed:.3f}\n")


if __name__ == "__main__":
    main()
