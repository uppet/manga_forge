#!/usr/bin/env python3
"""Small streamable-HTTP client for the local Windows delegate_runner."""

from __future__ import annotations

import json
import time
from dataclasses import dataclass
from typing import Any

import httpx


@dataclass(frozen=True)
class DelegateConfig:
    mcp_url: str
    proxy: str | None
    windows_shell: str


class DelegateClient:
    def __init__(self, config: DelegateConfig) -> None:
        self.config = config
        kwargs: dict[str, Any] = {"timeout": httpx.Timeout(60.0)}
        if config.proxy:
            kwargs["proxy"] = config.proxy
        self.client = httpx.Client(**kwargs)
        self.session_id: str | None = None
        self.next_id = 0
        self._initialize()

    def close(self) -> None:
        self.client.close()

    def _rpc(self, method: str, params: dict[str, Any] | None = None, notification: bool = False) -> dict[str, Any] | None:
        self.next_id += 1
        message: dict[str, Any] = {"jsonrpc": "2.0", "method": method}
        if not notification:
            message["id"] = self.next_id
        if params is not None:
            message["params"] = params
        headers = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream"}
        if self.session_id:
            headers["mcp-session-id"] = self.session_id
        response = self.client.post(self.config.mcp_url, json=message, headers=headers)
        response.raise_for_status()
        if self.session_id is None:
            self.session_id = response.headers.get("mcp-session-id")
        if notification or response.status_code == 202:
            return None
        if "text/event-stream" in response.headers.get("content-type", ""):
            for line in response.text.splitlines():
                if line.startswith("data:"):
                    return json.loads(line[5:].strip())
            raise RuntimeError("delegate_runner returned an empty event stream")
        return response.json()

    def _initialize(self) -> None:
        response = self._rpc(
            "initialize",
            {
                "protocolVersion": "2025-03-26",
                "capabilities": {},
                "clientInfo": {"name": "manga-forge-host", "version": "1.0"},
            },
        )
        if not response or "result" not in response:
            raise RuntimeError(f"delegate_runner initialize failed: {response}")
        self._rpc("notifications/initialized", notification=True)

    def call_tool(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:
        response = self._rpc("tools/call", {"name": name, "arguments": arguments})
        if not response:
            raise RuntimeError("delegate_runner returned no tool result")
        if "error" in response:
            raise RuntimeError(f"delegate_runner RPC error: {response['error']}")
        result = response.get("result", {})
        text = "\n".join(
            item.get("text", "")
            for item in result.get("content", [])
            if item.get("type") == "text"
        )
        try:
            return json.loads(text)
        except (json.JSONDecodeError, TypeError):
            return {"raw": text, "isError": result.get("isError", False)}

    def run(self, command: str, cwd: str, timeout: int = 900) -> dict[str, Any]:
        started = self.call_tool(
            "run_command",
            {
                "command": command,
                "cwd": cwd,
                "shell": self.config.windows_shell,
                "timeout": timeout,
            },
        )
        task_id = str(started.get("task_id") or started.get("id") or "")
        if not task_id:
            raise RuntimeError(f"delegate_runner did not return a task id: {started}")
        deadline = time.monotonic() + timeout + 30
        status: dict[str, Any] = {}
        while time.monotonic() < deadline:
            status = self.call_tool("get_task_status", {"task_id": task_id})
            if status.get("status") in {"completed", "failed", "cancelled", "timeout"}:
                break
            time.sleep(2.0)
        else:
            raise TimeoutError(f"delegate task {task_id} exceeded {timeout + 30}s")

        lines: list[str] = []
        offset = 0
        while True:
            output = self.call_tool("get_task_output", {"task_id": task_id, "offset": offset, "limit": 500})
            chunk = output.get("lines") or output.get("output") or output.get("raw") or []
            if isinstance(chunk, str):
                lines.append(chunk)
            else:
                for item in chunk:
                    if isinstance(item, dict):
                        stream = item.get("stream", "stdout")
                        lines.append(f"[{stream}] {item.get('text', '')}")
                    else:
                        lines.append(str(item))
            if not output.get("has_more"):
                break
            offset = int(output.get("next_offset", offset + 500))
        status["task_id"] = task_id
        status["rendered_output"] = "\n".join(lines)
        return status
