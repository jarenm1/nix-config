{ pkgs, ... }:

let
  mdPreview = pkgs.writeShellApplication {
    name = "md-preview";
    runtimeInputs = with pkgs; [
      python3
      pandoc
      mermaid-filter
      mermaid-cli
    ];
    text = ''
      set -euo pipefail

      show_help() {
        cat <<'EOF'
      Usage: md-preview [--port PORT] [--bind ADDRESS] FILE.md

      Starts a tiny local preview server for a Markdown file.
      - Renders standard Markdown with Pandoc
      - Renders Mermaid fences via mermaid-filter + mermaid-cli
      - Auto-reloads in the browser when the source file changes

      Examples:
        md-preview README.md
        md-preview --port 9000 docs/notes.md
        md-preview --bind 0.0.0.0 README.md
      EOF
      }

      port=6419
      bind=127.0.0.1

      while [ "$#" -gt 0 ]; do
        case "$1" in
          -p|--port)
            port="$2"
            shift 2
            ;;
          -b|--bind)
            bind="$2"
            shift 2
            ;;
          -h|--help)
            show_help
            exit 0
            ;;
          --)
            shift
            break
            ;;
          -*)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 2
            ;;
          *)
            break
            ;;
        esac
      done

      if [ "$#" -ne 1 ]; then
        show_help >&2
        exit 2
      fi

      source_file=$(realpath "$1")

      if [ ! -f "$source_file" ]; then
        echo "Markdown file not found: $1" >&2
        exit 1
      fi

      source_name=$(basename "$source_file")
      workdir=$(mktemp -d)

      cleanup() {
        rm -rf "$workdir"
      }

      trap cleanup EXIT INT TERM

      cat >"$workdir/pandoc-header.html" <<'EOF'
      <style>
        :root {
          color-scheme: light dark;
          --bg: #ffffff;
          --fg: #24292f;
          --muted: #57606a;
          --border: #d0d7de;
          --link: #0969da;
          --code-bg: #f6f8fa;
          --quote: #656d76;
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #0d1117;
            --fg: #e6edf3;
            --muted: #8b949e;
            --border: #30363d;
            --link: #58a6ff;
            --code-bg: #161b22;
            --quote: #9ea7b3;
          }
        }

        html {
          font-size: 16px;
        }

        body {
          margin: 0 auto;
          max-width: 960px;
          padding: 2rem 1.5rem 4rem;
          background: var(--bg);
          color: var(--fg);
          font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          line-height: 1.65;
          text-rendering: optimizeLegibility;
        }

        a {
          color: var(--link);
        }

        h1, h2, h3, h4, h5, h6 {
          margin-top: 2rem;
          margin-bottom: 0.75rem;
          line-height: 1.25;
          scroll-margin-top: 1rem;
        }

        p, ul, ol, blockquote, table, pre {
          margin: 1rem 0;
        }

        pre,
        code {
          font-family: "JetBrains Mono", "SFMono-Regular", ui-monospace, "Cascadia Code", Consolas, monospace;
        }

        code {
          background: var(--code-bg);
          border-radius: 0.35rem;
          padding: 0.1rem 0.35rem;
        }

        pre {
          background: var(--code-bg);
          border: 1px solid var(--border);
          border-radius: 0.65rem;
          overflow-x: auto;
          padding: 1rem;
        }

        pre code {
          background: transparent;
          padding: 0;
        }

        blockquote {
          border-left: 0.3rem solid var(--border);
          color: var(--quote);
          margin-left: 0;
          padding-left: 1rem;
        }

        table {
          border-collapse: collapse;
          display: block;
          overflow-x: auto;
          width: 100%;
        }

        th,
        td {
          border: 1px solid var(--border);
          padding: 0.55rem 0.8rem;
          text-align: left;
        }

        img,
        svg {
          display: block;
          height: auto;
          margin: 1.25rem auto;
          max-width: 100%;
        }

        hr {
          border: 0;
          border-top: 1px solid var(--border);
          margin: 2rem 0;
        }

        .md-preview-error {
          background: var(--code-bg);
          border: 1px solid var(--border);
          border-radius: 0.75rem;
          padding: 1rem;
        }
      </style>
      <script>
        let mdPreviewVersion = null;

        async function pollMdPreviewVersion() {
          try {
            const response = await fetch('/__version', { cache: 'no-store' });
            if (!response.ok) {
              throw new Error(`HTTP ''${response.status}`);
            }

            const nextVersion = (await response.text()).trim();

            if (mdPreviewVersion === null) {
              mdPreviewVersion = nextVersion;
            } else if (nextVersion !== mdPreviewVersion) {
              window.location.reload();
              return;
            }
          } catch (error) {
            console.debug('md-preview reload check failed', error);
          }

          window.setTimeout(pollMdPreviewVersion, 1000);
        }

        window.addEventListener('load', () => {
          window.setTimeout(pollMdPreviewVersion, 1000);
        });
      </script>
      EOF

      export SOURCE_FILE="$source_file"
      export SOURCE_NAME="$source_name"
      export WORKDIR="$workdir"
      export MD_PREVIEW_BIND="$bind"
      export MD_PREVIEW_PORT="$port"

      echo "Previewing $source_file at http://$bind:$port"
      if [ "$bind" = "127.0.0.1" ] || [ "$bind" = "localhost" ]; then
        echo "SSH forward: ssh -L $port:127.0.0.1:$port <host>"
        echo "Then open:   http://127.0.0.1:$port"
      fi
      echo "Press Ctrl-C to stop."

      exec python3 - <<'PY'
      import html
      import os
      import pathlib
      import subprocess
      from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

      source_file = pathlib.Path(os.environ["SOURCE_FILE"]).resolve()
      source_name = os.environ["SOURCE_NAME"]
      workdir = pathlib.Path(os.environ["WORKDIR"]).resolve()
      bind = os.environ["MD_PREVIEW_BIND"]
      port = int(os.environ["MD_PREVIEW_PORT"])
      header_file = workdir / "pandoc-header.html"
      preview_file = workdir / "preview.html"
      version_file = workdir / "version.txt"


      def source_version() -> str:
          stats = source_file.stat()
          return f"{stats.st_mtime_ns}:{stats.st_size}"


      def write_error_preview(stamp: str, message: str) -> None:
          preview_file.write_text(
              """<!doctype html>
      <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <title>Markdown preview error</title>
        <style>
          body {
            font-family: Inter, ui-sans-serif, system-ui, sans-serif;
            line-height: 1.6;
            margin: 0 auto;
            max-width: 960px;
            padding: 2rem 1.5rem 4rem;
          }

          pre {
            background: #161b22;
            border-radius: 0.75rem;
            color: #e6edf3;
            overflow-x: auto;
            padding: 1rem;
          }
        </style>
      </head>
      <body>
        <h1>Preview render failed</h1>
        <div class=\"md-preview-error\">
          <pre>"""
              + html.escape(message)
              + """</pre>
        </div>
      </body>
      </html>
      """,
              encoding="utf-8",
          )
          version_file.write_text(stamp, encoding="utf-8")


      def render_preview() -> str:
          try:
              stamp = source_version()
          except FileNotFoundError:
              stamp = "missing"
              write_error_preview(stamp, f"Source file is missing: {source_file}")
              return stamp

          if preview_file.exists() and version_file.exists():
              current = version_file.read_text(encoding="utf-8")
              if current == stamp:
                  return stamp

          command = [
              "pandoc",
              str(source_file),
              "--from=gfm+smart",
              "--to=html5",
              "--standalone",
              "--embed-resources",
              "--highlight-style=pygments",
              "--filter=mermaid-filter",
              "--include-in-header",
              str(header_file),
              "--metadata",
              f"title={source_name}",
              "--resource-path",
              str(source_file.parent),
              "--output",
              str(preview_file),
          ]

          result = subprocess.run(
              command,
              capture_output=True,
              cwd=source_file.parent,
              text=True,
          )

          if result.returncode != 0:
              details = result.stderr.strip() or result.stdout.strip() or "Pandoc failed without output."
              write_error_preview(stamp, details)
              return stamp

          version_file.write_text(stamp, encoding="utf-8")
          return stamp


      class PreviewHandler(BaseHTTPRequestHandler):
          def log_message(self, format: str, *args) -> None:
              return

          def send_text(self, body: str, content_type: str, status: int = 200) -> None:
              payload = body.encode("utf-8")
              self.send_response(status)
              self.send_header("Content-Type", content_type)
              self.send_header("Content-Length", str(len(payload)))
              self.send_header("Cache-Control", "no-store")
              self.end_headers()
              self.wfile.write(payload)

          def send_bytes(self, payload: bytes, content_type: str, status: int = 200) -> None:
              self.send_response(status)
              self.send_header("Content-Type", content_type)
              self.send_header("Content-Length", str(len(payload)))
              self.send_header("Cache-Control", "no-store")
              self.end_headers()
              self.wfile.write(payload)

          def do_GET(self) -> None:
              path = self.path.split("?", 1)[0]

              if path == "/favicon.ico":
                  self.send_response(204)
                  self.end_headers()
                  return

              if path == "/__version":
                  self.send_text(render_preview(), "text/plain; charset=utf-8")
                  return

              if path in {"/", "/index.html"}:
                  render_preview()
                  self.send_bytes(preview_file.read_bytes(), "text/html; charset=utf-8")
                  return

              self.send_text("Not found", "text/plain; charset=utf-8", status=404)


      class PreviewServer(ThreadingHTTPServer):
          allow_reuse_address = True


      render_preview()
      server = PreviewServer((bind, port), PreviewHandler)

      try:
          server.serve_forever()
      except KeyboardInterrupt:
          pass
      finally:
          server.server_close()
      PY
    '';
  };
in
{
  home.packages = [ mdPreview ];
}
