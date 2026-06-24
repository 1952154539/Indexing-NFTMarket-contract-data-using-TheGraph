#!/usr/bin/env python3
"""Generate HTML pages for TheGraph query screenshots."""

import json, subprocess, os

QUERY_ENDPOINT = "https://api.studio.thegraph.com/query/1755602/nftmarket-sepolia/v0.0.3"
SCREENSHOTS_DIR = os.path.dirname(os.path.abspath(__file__))

def query_graphql(query: str) -> dict:
    result = subprocess.run([
        "curl", "-s", "-X", "POST", QUERY_ENDPOINT,
        "-H", "Content-Type: application/json",
        "-H", "User-Agent: Mozilla/5.0",
        "-d", json.dumps({"query": query})
    ], capture_output=True, text=True, timeout=15)
    return json.loads(result.stdout)

def html_page(title: str, graphql: str, result: str, description: str = "") -> str:
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{title}</title>
<style>
* {{ margin: 0; padding: 0; box-sizing: border-box; }}
body {{ font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace; background: #1a1b2e; color: #e2e8f0; padding: 30px; }}
h2 {{ color: #a78bfa; font-size: 18px; margin-bottom: 8px; }}
.desc {{ color: #94a3b8; font-size: 13px; margin-bottom: 20px; }}
.section {{ background: #0f0f1a; border: 1px solid #2d2d4a; border-radius: 8px; margin-bottom: 20px; overflow: hidden; }}
.section-header {{ background: #1e1e36; padding: 10px 16px; font-size: 12px; color: #6b7280; text-transform: uppercase; letter-spacing: 1px; }}
.query-code {{ padding: 16px; font-size: 13px; line-height: 1.6; color: #e2e8f0; white-space: pre-wrap; overflow-x: auto; }}
.query-code .kw {{ color: #c084fc; }}
.query-code .str {{ color: #6ee7b7; }}
.query-code .num {{ color: #f9a8d4; }}
.result-code {{ padding: 16px; font-size: 13px; line-height: 1.6; color: #a5b4fc; white-space: pre-wrap; overflow-x: auto; max-height: 500px; overflow-y: auto; }}
.result-code .key {{ color: #93c5fd; }}
.result-code .string {{ color: #6ee7b7; }}
.result-code .number {{ color: #f9a8d4; }}
.badge {{ display: inline-block; background: #059669; color: #fff; padding: 2px 8px; border-radius: 4px; font-size: 11px; margin-left: 8px; }}
.endpoint {{ font-size: 11px; color: #6b7280; margin-bottom: 16px; }}
.endpoint span {{ color: #6ee7b7; }}
</style>
</head>
<body>
<div class="endpoint">Endpoint: <span>{QUERY_ENDPOINT}</span></div>
<h2>{title} <span class="badge">Live Data</span></h2>
{description}
<div class="section">
  <div class="section-header">GraphQL Query</div>
  <div class="query-code">{graphql}</div>
</div>
<div class="section">
  <div class="section-header">Result (JSON)</div>
  <div class="result-code">{result}</div>
</div>
</body>
</html>"""

queries = [
    ("Query 1: Get All Listings", """{
  lists(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    nft
    tokenId
    tokenURL
    seller
    payToken
    price
    deadline
    cancelTxHash
    filledTxHash
  }
}"""),
    ("Query 2: Sold Records with Listing Details", """{
  solds(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    buyer
    fee
    blockTimestamp
    transactionHash
    list {
      id
      nft
      tokenId
      tokenURL
      seller
      price
      payToken
    }
  }
}"""),
    ("Query 3: Cancelled Listings", """{
  lists(
    where: { cancelTxHash_not: "0x00000000" }
    first: 10
  ) {
    id
    nft
    tokenId
    price
    seller
    cancelTxHash
    blockTimestamp
  }
}"""),
    ("Query 4: Single Listing Detail", """{
  list(id: "0x01") {
    id
    nft
    tokenId
    tokenURL
    seller
    payToken
    price
    deadline
    blockNumber
    blockTimestamp
    transactionHash
    cancelTxHash
    filledTxHash
  }
}"""),
]

os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

for i, (title, query) in enumerate(queries):
    print(f"Processing {title}...")
    data = query_graphql(query)
    pretty = json.dumps(data, indent=2)

    html_path = os.path.join(SCREENSHOTS_DIR, f"query{i+1}.html")
    with open(html_path, "w") as f:
        f.write(html_page(title, query, pretty))

    png_path = os.path.join(SCREENSHOTS_DIR, f"query{i+1}.png")
    result = subprocess.run([
        "firefox", "--headless", "--screenshot", png_path,
        "--window-size", "800,600", "--no-remote", "--new-instance",
        "--profile", "/tmp/firefox_screenshot", f"file://{html_path}"
    ], capture_output=True, text=True, timeout=30)

    if os.path.exists(png_path):
        size = os.path.getsize(png_path)
        print(f"  -> {png_path} ({size} bytes)")
    else:
        print(f"  -> FAILED: {result.stderr[:200]}")
        # Try smaller window
        result2 = subprocess.run([
            "firefox", "--headless", "--screenshot", png_path,
            "--window-size", "800,500", "--no-remote", "--new-instance",
            "--profile", "/tmp/firefox_screenshot2", f"file://{html_path}"
        ], capture_output=True, text=True, timeout=30)
        if os.path.exists(png_path):
            print(f"  -> {png_path} ({os.path.getsize(png_path)} bytes) [retry ok]")
        else:
            print(f"  -> FAILED again: {result2.stderr[:200]}")

print("Done!")
