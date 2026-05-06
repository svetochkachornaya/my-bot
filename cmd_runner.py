import os, json, time, subprocess, urllib.request, urllib.error, base64

def load_env(path="/root/my-bot/.env"):
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))

load_env()

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GH_USER = os.environ.get("GH_USER", "svetochkachornaya")
REPO_NAME = os.environ.get("REPO_NAME", "my-bot")
API_BASE = f"https://api.github.com/repos/{GH_USER}/{REPO_NAME}/contents"
HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json",
    "User-Agent": "cmd-runner/1.0",
}

def gh_get(path):
    req = urllib.request.Request(f"{API_BASE}/{path}", headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

def gh_put(path, content_str, sha, message):
    data = json.dumps({
        "message": message,
        "content": base64.b64encode(content_str.encode()).decode(),
        "sha": sha,
    }).encode()
    req = urllib.request.Request(
        f"{API_BASE}/{path}", data=data,
        headers={**HEADERS, "Content-Type": "application/json"},
        method="PUT",
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())

last_id = None

while True:
    try:
        pending_data = gh_get("cmds/pending.json")
        content = json.loads(base64.b64decode(pending_data["content"]).decode())
        cmd_id = content.get("id", "")
        cmd = content.get("cmd", "")

        if cmd_id and cmd_id != last_id and cmd:
            last_id = cmd_id
            try:
                proc = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
                output = (proc.stdout + proc.stderr)[-3000:]
                status = "ok" if proc.returncode == 0 else "error"
            except subprocess.TimeoutExpired:
                output = "Timeout (120s)"
                status = "timeout"
            except Exception as e:
                output = str(e)
                status = "error"

            result_data = gh_get("cmds/result.json")
            result_str = json.dumps(
                {"id": cmd_id, "status": status, "output": output},
                ensure_ascii=False, indent=2
            )
            gh_put("cmds/result.json", result_str, result_data["sha"], f"result: {cmd_id}")
    except Exception:
        pass
    time.sleep(5)
