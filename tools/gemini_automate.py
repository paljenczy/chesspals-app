#!/usr/bin/env python3
"""
Automate avatar generation via Gemini's web UI using Chrome DevTools Protocol.

Prerequisites:
  - Chrome open with Gemini (logged in) on debug port 9222
  - pip install websockets

Usage:
    python3 tools/gemini_automate.py
    python3 tools/gemini_automate.py --output-dir ~/Downloads/chesspals_avatars
    python3 tools/gemini_automate.py --start-from 5
    python3 tools/gemini_automate.py --delay 45
"""

import asyncio
import argparse
import base64
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

# ─── Prompt data (mirrors prompt_helper.html) ────────────────────────────────

BASE_TEMPLATE = (
    "A soft watercolor illustration of a cute {ANIMAL} character's face, "
    "designed as a circular avatar for a children's chess app. "
    "Extreme close-up: the face fills the entire frame, edge-to-edge. "
    "Render the artwork inside a perfect circle with a thin solid dark brown "
    "outline around the circle edge and a plain white background outside "
    "the circle.\n"
    "Round friendly face, big expressive eyes, gentle brushstrokes, muted "
    "pastel palette, warm inviting children's storybook style. {FEATURES}, "
    "{EMOTION}. Clean minimal design. No text, no outer glow, no vignette, "
    "and no additional background\u2014only the circular {ANIMAL} face with "
    "a thin dark brown border and white outside area."
)

ANIMALS = [
    {'id': 'bee',         'name': 'Bella the Bee',         'features': 'small antennae, yellow\u2011and\u2011black stripes'},
    {'id': 'butterfly',   'name': 'Flutter the Butterfly',  'features': 'small colorful wings, curly antennae'},
    {'id': 'hummingbird', 'name': 'Zip the Hummingbird',    'features': 'small pointed beak, iridescent blue\u2011green feathers'},
    {'id': 'rabbit',      'name': 'Rosie the Rabbit',       'features': 'long floppy ears, pink nose, white fluffy cheeks'},
    {'id': 'kangaroo',    'name': 'Kira the Kangaroo',      'features': 'rounded ears, light tan fur, brown nose'},
    {'id': 'deer',        'name': 'Dino the Deer',          'features': 'small rounded antlers, light brown fur with white spots'},
    {'id': 'giraffe',     'name': 'Gabi the Giraffe',       'features': 'small ossicones, long eyelashes, golden fur with brown patches'},
    {'id': 'tiger',       'name': 'Tara the Tiger',         'features': 'rounded ears, orange fur with black stripes, white muzzle'},
]

EMOTIONS = [
    {'id': 'neutral', 'desc': 'calm neutral expression: relaxed round eyes looking forward, flat eyebrows, small closed\u2011mouth gentle smile, no teeth showing'},
    {'id': 'happy',   'desc': 'very happy expression: eyes squeezed shut into upward crescents, eyebrows raised high, wide open mouth showing teeth in a big grin, bright rosy cheeks, visible blush marks'},
    {'id': 'sad',     'desc': 'clearly sad expression: half\u2011closed droopy eyes looking downward, inner eyebrows tilted up in worry, small downturned frown mouth, one visible blue teardrop rolling down cheek'},
    {'id': 'scared',  'desc': 'visibly scared expression: eyes wide open with shrunk pupils, eyebrows raised very high and pinched together, tiny round open mouth in an O shape, a sweat drop on forehead, trembling look'},
    {'id': 'furious', 'desc': 'angry frustrated expression: eyes glaring with sharp V\u2011shaped angry eyebrows, nostrils flared, mouth in a grumpy zigzag frown showing gritted teeth, puffed\u2011out red cheeks, steam lines above head, but still cute'},
]

# Hummingbird has a beak, not a separate mouth — override emotion descriptions
HUMMINGBIRD_EMOTIONS = [
    {'id': 'neutral', 'desc': 'calm neutral expression: relaxed round eyes looking forward, flat eyebrows, beak closed in a gentle resting position'},
    {'id': 'happy',   'desc': 'very happy expression: eyes squeezed shut into upward crescents, eyebrows raised high, beak open wide in a cheerful chirp, bright rosy cheeks, visible blush marks'},
    {'id': 'sad',     'desc': 'clearly sad expression: half\u2011closed droopy eyes looking downward, inner eyebrows tilted up in worry, beak slightly open and drooping downward, one visible blue teardrop rolling down cheek'},
    {'id': 'scared',  'desc': 'visibly scared expression: eyes wide open with shrunk pupils, eyebrows raised very high and pinched together, beak clamped shut and trembling, a sweat drop on forehead, trembling look'},
    {'id': 'furious', 'desc': 'angry frustrated expression: eyes glaring with sharp V\u2011shaped angry eyebrows, beak open showing an angry squawk, puffed\u2011out red cheeks, steam lines above head, but still cute'},
]


def build_prompts():
    """Build all 40 prompt entries."""
    prompts = []
    for animal in ANIMALS:
        emotions = HUMMINGBIRD_EMOTIONS if animal['id'] == 'hummingbird' else EMOTIONS
        for emotion in emotions:
            text = (BASE_TEMPLATE
                    .replace('{ANIMAL}', animal['id'])
                    .replace('{FEATURES}', animal['features'])
                    .replace('{EMOTION}', emotion['desc']))
            prompts.append({
                'animal': animal['id'],
                'emotion': emotion['id'],
                'filename': f"{animal['id']}_{emotion['id']}.png",
                'prompt': text,
            })
    return prompts


# ─── CDP helper ───────────────────────────────────────────────────────────────

class GeminiAutomator:
    def __init__(self, port=9222, debug=False):
        self.port = port
        self.debug = debug
        self.ws = None
        self._msg_id = 0
        self._pending_events = []  # Buffer for CDP events received while waiting for responses

    async def connect(self):
        """Find the Gemini tab and connect via websocket."""
        url = f'http://127.0.0.1:{self.port}/json'
        with urllib.request.urlopen(url) as resp:
            tabs = json.loads(resp.read())

        gemini_tab = None
        for tab in tabs:
            if tab.get('type') == 'page' and 'gemini.google.com' in tab.get('url', ''):
                gemini_tab = tab
                break

        if not gemini_tab:
            print("ERROR: No Gemini tab found. Open gemini.google.com in the debug Chrome.")
            sys.exit(1)

        ws_url = gemini_tab['webSocketDebuggerUrl']
        print(f"Connecting to: {gemini_tab['title']}")
        print(f"  URL: {gemini_tab['url']}")

        import websockets
        self.ws = await websockets.connect(ws_url, max_size=50 * 1024 * 1024)
        # Enable Runtime and Page domains
        await self._send('Runtime.enable', {})
        await self._send('Page.enable', {})
        await self._send('Page.setInterceptFileChooserDialog', {'enabled': True})
        print("Connected!\n")

    async def _send(self, method, params=None):
        """Send a CDP command and return the result."""
        self._msg_id += 1
        msg_id = self._msg_id
        msg = {'id': msg_id, 'method': method, 'params': params or {}}
        if self.debug:
            print(f"  CDP → {method}")
        await self.ws.send(json.dumps(msg))

        # Read responses until we get ours, buffering events
        while True:
            raw = await self.ws.recv()
            data = json.loads(raw)
            if data.get('id') == msg_id:
                if 'error' in data:
                    raise RuntimeError(f"CDP error: {data['error']}")
                return data.get('result', {})
            # Buffer events for later processing
            if 'method' in data:
                self._pending_events.append(data)

    async def _evaluate(self, expression, await_promise=False):
        """Evaluate JS in the page and return the value."""
        params = {'expression': expression, 'returnByValue': True}
        if await_promise:
            params['awaitPromise'] = True
        result = await self._send('Runtime.evaluate', params)
        inner = result.get('result', {})
        if inner.get('subtype') == 'error':
            raise RuntimeError(f"JS error: {inner.get('description', inner)}")
        return inner.get('value')

    async def navigate_new_chat(self):
        """Navigate to a fresh Gemini chat."""
        await self._send('Page.navigate', {'url': 'https://gemini.google.com/app'})
        # Wait for page load
        await asyncio.sleep(4)
        # Wait for the textbox to appear
        for _ in range(15):
            ready = await self._evaluate(
                'document.querySelector(\'div.ql-editor[role="textbox"]\') !== null'
            )
            if ready:
                return
            await asyncio.sleep(1)
        print("  WARNING: Textbox not found after navigation")

    async def upload_reference_image(self, file_path):
        """Upload a reference image to the current Gemini chat."""
        await self._send('DOM.enable', {})

        # Open the menu to mount the uploader component
        await self._evaluate(
            '''document.querySelector('button.menu-button')?.click(); 'done' '''
        )
        await asyncio.sleep(1.5)

        # Handle consent dialog if it appears
        consent = await self._evaluate('''
        (() => {
            const d = document.querySelector('mat-dialog-container');
            if (!d) return 'NO_DIALOG';
            for (const b of d.querySelectorAll('button')) {
                if (b.textContent.trim() === 'Agree') { b.click(); return 'AGREED'; }
            }
            return 'NO_AGREE';
        })()
        ''')
        if consent == 'AGREED':
            await asyncio.sleep(2)
            # Reopen menu after consent
            await self._evaluate(
                '''document.querySelector('button.menu-button')?.click(); 'done' '''
            )
            await asyncio.sleep(1.5)

        # Click the upload-menu-item with real mouse events to trigger file input creation
        coords_json = await self._evaluate('''
        (() => {
            const item = document.querySelector('.upload-menu-item');
            if (!item) return null;
            const rect = item.getBoundingClientRect();
            return JSON.stringify({x: rect.x + rect.width/2, y: rect.y + rect.height/2});
        })()
        ''')
        if not coords_json:
            print("  WARNING: Upload menu item not found")
            return False

        coords = json.loads(coords_json)
        x, y = coords['x'], coords['y']
        await self._send('Input.dispatchMouseEvent', {
            'type': 'mousePressed', 'x': x, 'y': y,
            'button': 'left', 'clickCount': 1,
        })
        await self._send('Input.dispatchMouseEvent', {
            'type': 'mouseReleased', 'x': x, 'y': y,
            'button': 'left', 'clickCount': 1,
        })
        await asyncio.sleep(2)

        # Get fresh DOM tree and find the file input
        doc = await self._send('DOM.getDocument', {'depth': -1})
        root_id = doc['root']['nodeId']
        result = await self._send('DOM.querySelector', {
            'nodeId': root_id,
            'selector': 'input[type="file"]',
        })
        node_id = result.get('nodeId', 0)
        if not node_id:
            print("  WARNING: File input not found after menu click")
            return False

        # Set the file
        await self._send('DOM.setFileInputFiles', {
            'nodeId': node_id,
            'files': [str(file_path)],
        })

        # Wait for attachment chip to appear
        for _ in range(10):
            await asyncio.sleep(1)
            attached = await self._evaluate(
                'document.querySelector("gem-media-attachment, .file-preview-chip") !== null'
            )
            if attached:
                return True

        print("  WARNING: File attachment not confirmed")
        return False

    async def type_prompt(self, text):
        """Type the prompt into Gemini's textbox using CDP Input.insertText."""
        # Focus the editor via JS
        focused = await self._evaluate('''
        (() => {
            const editor = document.querySelector('div.ql-editor[role="textbox"]');
            if (!editor) return 'NO_EDITOR';
            editor.focus();
            // Clear any existing text
            const sel = window.getSelection();
            sel.selectAllChildren(editor);
            return 'OK';
        })()
        ''')
        if focused != 'OK':
            raise RuntimeError(f"Failed to focus editor: {focused}")

        # Clear existing content with Delete key
        await self._send('Input.dispatchKeyEvent', {
            'type': 'keyDown', 'key': 'Delete', 'code': 'Delete',
            'windowsVirtualKeyCode': 46, 'nativeVirtualKeyCode': 46,
        })
        await self._send('Input.dispatchKeyEvent', {
            'type': 'keyUp', 'key': 'Delete', 'code': 'Delete',
            'windowsVirtualKeyCode': 46, 'nativeVirtualKeyCode': 46,
        })
        await asyncio.sleep(0.2)

        # Use CDP Input.insertText to bypass TrustedHTML restrictions
        await self._send('Input.insertText', {'text': text})
        await asyncio.sleep(0.3)

    async def submit(self):
        """Submit the prompt by clicking the send button."""
        # Small delay to let Gemini register the input
        await asyncio.sleep(0.5)

        # Try clicking the send button via JS
        for attempt in range(3):
            result = await self._evaluate('''
            (() => {
                const btn = document.querySelector('button.send-button');
                if (!btn) return 'NO_BUTTON';
                if (btn.disabled) return 'DISABLED';
                btn.click();
                return 'OK';
            })()
            ''')
            if result == 'OK':
                return
            if result == 'DISABLED':
                await asyncio.sleep(1)
                continue
            break

        # Fallback: press Enter via CDP
        if result != 'OK':
            print(f"  Send button issue ({result}), trying Enter key...")
            await self._send('Input.dispatchKeyEvent', {
                'type': 'keyDown', 'key': 'Enter', 'code': 'Enter',
                'windowsVirtualKeyCode': 13, 'nativeVirtualKeyCode': 13,
            })
            await self._send('Input.dispatchKeyEvent', {
                'type': 'keyUp', 'key': 'Enter', 'code': 'Enter',
                'windowsVirtualKeyCode': 13, 'nativeVirtualKeyCode': 13,
            })

    async def wait_for_image(self, timeout=180):
        """Wait for Gemini to generate an image and return its URL/data."""
        print("  Waiting for image generation...", end='', flush=True)
        start = time.time()
        dots = 0

        while time.time() - start < timeout:
            # Check for generated images in the response area
            # Gemini renders images as <img> inside response containers
            result = await self._evaluate('''
            (() => {
                // Look for images in model response turns
                const responses = document.querySelectorAll('model-response, .model-response-text, message-content, .response-container');
                // Also look broadly for any recent large image
                const allImgs = document.querySelectorAll('img');
                const candidates = [];
                for (const img of allImgs) {
                    const src = img.src || '';
                    const w = img.naturalWidth || img.width || 0;
                    // Filter: must be a real generated image (not icon/avatar)
                    // Generated images from Gemini typically have googleusercontent or blob URLs
                    // and are large (>100px)
                    if (w > 100 && (
                        src.includes('googleusercontent.com') ||
                        src.includes('blob:') ||
                        src.includes('data:image') ||
                        src.includes('lh3.') ||
                        src.includes('generated_image')
                    )) {
                        candidates.push({
                            src: src.substring(0, 500),
                            width: w,
                            height: img.naturalHeight || img.height || 0,
                        });
                    }
                }
                // Also check for pending/loading indicators
                const loading = document.querySelector('.loading-indicator, .thinking-indicator, mat-progress-bar, .progress-bar-container');
                const isLoading = loading !== null && loading.offsetParent !== null;

                return JSON.stringify({
                    candidates: candidates,
                    isLoading: isLoading,
                    totalImgs: allImgs.length,
                });
            })()
            ''')

            data = json.loads(result)
            candidates = data.get('candidates', [])

            if candidates:
                # Return the last (most recent) candidate
                img = candidates[-1]
                elapsed = int(time.time() - start)
                print(f" found! ({elapsed}s)")
                return img

            # Print progress dot
            dots += 1
            if dots % 5 == 0:
                elapsed = int(time.time() - start)
                print(f" {elapsed}s", end='', flush=True)
            else:
                print('.', end='', flush=True)

            await asyncio.sleep(3)

        print(f" TIMEOUT after {timeout}s")
        return None

    async def download_image(self, img_info, output_path):
        """Download the generated image and save to disk."""
        src = img_info['src']

        if src.startswith('data:image'):
            # Base64-encoded data URL
            header, b64data = src.split(',', 1)
            img_data = base64.b64decode(b64data)
            with open(output_path, 'wb') as f:
                f.write(img_data)
            return True

        if src.startswith('blob:'):
            # Can't directly download blob URLs from outside the page
            # Use canvas to convert to base64
            b64 = await self._evaluate(f'''
            (async () => {{
                try {{
                    const img = document.querySelector('img[src="{src}"]');
                    if (!img) return null;
                    const canvas = document.createElement('canvas');
                    canvas.width = img.naturalWidth;
                    canvas.height = img.naturalHeight;
                    const ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0);
                    return canvas.toDataURL('image/png').split(',')[1];
                }} catch(e) {{
                    return 'ERROR:' + e.message;
                }}
            }})()
            ''', await_promise=True)

            if b64 and not str(b64).startswith('ERROR'):
                img_data = base64.b64decode(b64)
                with open(output_path, 'wb') as f:
                    f.write(img_data)
                return True
            else:
                print(f"  WARNING: blob download failed: {b64}")

        if src.startswith('http'):
            # Fetch via the page (to include cookies/auth)
            b64 = await self._evaluate(f'''
            (async () => {{
                try {{
                    const resp = await fetch("{src}");
                    const blob = await resp.blob();
                    return new Promise((resolve) => {{
                        const reader = new FileReader();
                        reader.onload = () => resolve(reader.result.split(',')[1]);
                        reader.readAsDataURL(blob);
                    }});
                }} catch(e) {{
                    return 'ERROR:' + e.message;
                }}
            }})()
            ''', await_promise=True)

            if b64 and not str(b64).startswith('ERROR'):
                img_data = base64.b64decode(b64)
                with open(output_path, 'wb') as f:
                    f.write(img_data)
                return True
            else:
                print(f"  WARNING: HTTP download failed: {b64}")

        # Fallback: try to find the image and screenshot it via canvas
        print("  Attempting canvas fallback...")
        b64 = await self._evaluate('''
        (async () => {
            const imgs = document.querySelectorAll('img');
            let best = null;
            for (const img of imgs) {
                const w = img.naturalWidth || 0;
                if (w > 100 && (!best || w > (best.naturalWidth || 0))) {
                    best = img;
                }
            }
            if (!best) return null;
            const canvas = document.createElement('canvas');
            canvas.width = best.naturalWidth;
            canvas.height = best.naturalHeight;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(best, 0, 0);
            return canvas.toDataURL('image/png').split(',')[1];
        })()
        ''', await_promise=True)

        if b64 and b64 != 'null':
            img_data = base64.b64decode(b64)
            with open(output_path, 'wb') as f:
                f.write(img_data)
            return True

        print("  ERROR: Could not download image via any method")
        return False

    async def count_current_images(self):
        """Count how many generated images are currently on the page (excluding uploaded attachments)."""
        result = await self._evaluate('''
        (() => {
            let count = 0;
            const imgs = document.querySelectorAll('img');
            for (const img of imgs) {
                if (img.closest('gem-media-attachment, uploader-file-preview, .file-preview-chip')) continue;
                const w = img.naturalWidth || img.width || 0;
                const src = img.src || '';
                if (w > 100 && (
                    src.includes('googleusercontent.com') ||
                    src.includes('blob:') ||
                    src.includes('data:image') ||
                    src.includes('lh3.')
                )) count++;
            }
            return count;
        })()
        ''')
        return result or 0

    async def wait_for_new_image(self, prev_count, timeout=180):
        """Wait for a NEW image to appear (count > prev_count)."""
        print("  Waiting for image generation...", end='', flush=True)
        start = time.time()
        dots = 0

        while time.time() - start < timeout:
            # First check if Gemini is still "thinking"
            still_thinking = await self._evaluate('''
            (() => {
                // Gemini shows a thinking/loading state
                const thinking = document.querySelector('.loading-container, .thinking-container, mat-progress-bar');
                if (thinking && thinking.offsetParent !== null) return true;
                // Also check for the stop button (visible while generating)
                const stopBtn = document.querySelector('button[aria-label*="top"], button[aria-label*="llít"]');
                if (stopBtn && stopBtn.offsetParent !== null) return true;
                return false;
            })()
            ''')

            current = await self.count_current_images()
            if current > prev_count:
                elapsed = int(time.time() - start)
                print(f" found! ({elapsed}s)")
                # Get the latest image info
                result = await self._evaluate('''
                (() => {
                    const imgs = document.querySelectorAll('img');
                    let best = null;
                    for (const img of imgs) {
                        if (img.closest('gem-media-attachment, uploader-file-preview, .file-preview-chip')) continue;
                        const w = img.naturalWidth || img.width || 0;
                        const src = img.src || '';
                        if (w > 100 && (
                            src.includes('googleusercontent.com') ||
                            src.includes('blob:') ||
                            src.includes('data:image') ||
                            src.includes('lh3.')
                        )) best = { src: src.substring(0, 500), width: w, height: img.naturalHeight || img.height || 0 };
                    }
                    return JSON.stringify(best);
                })()
                ''')
                return json.loads(result) if result else None

            dots += 1
            if dots % 5 == 0:
                elapsed = int(time.time() - start)
                status = "loading" if still_thinking else "waiting"
                print(f" {elapsed}s ({status})", end='', flush=True)
            else:
                print('.', end='', flush=True)

            await asyncio.sleep(3)

        print(f" TIMEOUT after {timeout}s")
        return None

    @staticmethod
    def _find_reference_image(output_dir, animal):
        """Find an existing image for this animal to use as style reference.
        Prefers neutral, then any available emotion."""
        output_dir = Path(output_dir)
        # Prefer neutral as reference
        neutral = output_dir / f"{animal}_neutral.png"
        if neutral.exists() and neutral.stat().st_size > 1000:
            return neutral
        # Fall back to any existing emotion for this animal
        for emotion in ['happy', 'sad', 'scared', 'furious']:
            path = output_dir / f"{animal}_{emotion}.png"
            if path.exists() and path.stat().st_size > 1000:
                return path
        # No reference available for this animal — try another animal's neutral
        for other_animal in ['bee', 'butterfly', 'hummingbird', 'rabbit',
                             'kangaroo', 'deer', 'giraffe', 'tiger']:
            if other_animal == animal:
                continue
            path = output_dir / f"{other_animal}_neutral.png"
            if path.exists() and path.stat().st_size > 1000:
                return path
        return None

    async def run(self, output_dir, start_from=0, delay=30, timeout=180):
        """Run the full automation loop, grouped by animal for style consistency."""
        prompts = build_prompts()
        output_dir = Path(output_dir)
        output_dir.mkdir(parents=True, exist_ok=True)

        total = len(prompts)
        succeeded = 0
        failed = []
        skipped = 0

        print(f"Output directory: {output_dir}")
        print(f"Total prompts: {total}")
        print(f"Starting from: #{start_from}")
        print(f"Delay between prompts: {delay}s")
        print(f"Image timeout: {timeout}s")
        print("(Grouped by animal — 5 emotions per chat for style consistency)")
        print("=" * 60)

        current_animal = None

        for i, entry in enumerate(prompts):
            if i < start_from:
                continue

            filename = entry['filename']
            output_path = output_dir / filename

            # Skip if already exists
            if output_path.exists() and output_path.stat().st_size > 1000:
                print(f"[{i+1}/{total}] {filename} — already exists, skipping")
                skipped += 1
                continue

            print(f"\n[{i+1}/{total}] {entry['animal']} / {entry['emotion']}")
            print(f"  File: {filename}")

            try:
                # Only open a new chat when the animal changes
                if entry['animal'] != current_animal:
                    current_animal = entry['animal']
                    print(f"  Starting new chat for {current_animal}...")
                    await self.navigate_new_chat()
                    await asyncio.sleep(2)

                    # Upload a reference image for style consistency
                    ref_image = self._find_reference_image(output_dir, current_animal)
                    if ref_image:
                        print(f"  Uploading style reference: {ref_image.name}")
                        uploaded = await self.upload_reference_image(ref_image)
                        if uploaded:
                            # Type a style-priming instruction alongside the image
                            await self.type_prompt(
                                "Use the attached image as a style reference. "
                                "Generate the following images in the exact same "
                                "watercolor style, color palette, and level of detail."
                            )
                            await asyncio.sleep(0.5)
                            await self.submit()
                            # Wait for Gemini to finish responding to the priming
                            print("  Waiting for style priming response...", end='', flush=True)
                            await asyncio.sleep(5)
                            for _ in range(30):
                                still_loading = await self._evaluate('''
                                (() => {
                                    const stop = document.querySelector('button[aria-label*="top"], button[aria-label*="llít"]');
                                    return stop !== null && stop.offsetParent !== null;
                                })()
                                ''')
                                if not still_loading:
                                    break
                                await asyncio.sleep(2)
                            print(" done")
                        else:
                            print("  Continuing without reference image")

                # Count images before we submit
                img_count_before = await self.count_current_images()

                # Type the prompt
                print("  Typing prompt...")
                await self.type_prompt(entry['prompt'])
                await asyncio.sleep(1)

                # Submit
                print("  Submitting...")
                await self.submit()

                # Wait for new image
                img_info = await self.wait_for_new_image(img_count_before, timeout=timeout)

                if img_info:
                    # Download it
                    print(f"  Downloading ({img_info['width']}x{img_info['height']})...")
                    ok = await self.download_image(img_info, str(output_path))
                    if ok:
                        size_kb = output_path.stat().st_size / 1024
                        print(f"  SAVED: {output_path} ({size_kb:.0f} KB)")
                        succeeded += 1
                    else:
                        failed.append(filename)
                        print(f"  FAILED to download")
                else:
                    failed.append(filename)
                    print(f"  FAILED: no image generated")

            except Exception as e:
                failed.append(filename)
                print(f"  ERROR: {e}")

            # Delay before next prompt
            if i < total - 1:
                print(f"  Waiting {delay}s before next prompt...")
                await asyncio.sleep(delay)

        # Summary
        print("\n" + "=" * 60)
        print(f"DONE! Succeeded: {succeeded}, Failed: {len(failed)}, Skipped: {skipped}")
        if failed:
            print(f"\nFailed files:")
            for f in failed:
                print(f"  - {f}")
            print(f"\nTo retry failed ones, delete them and run again.")
        print(f"\nNext step: python3 tools/process_avatars.py {output_dir}")

    async def close(self):
        if self.ws:
            await self.ws.close()


async def main():
    parser = argparse.ArgumentParser(description='Automate Gemini avatar generation via CDP')
    parser.add_argument('--output-dir', type=str,
                        default=os.path.expanduser('~/Downloads/chesspals_avatars'),
                        help='Directory to save generated images')
    parser.add_argument('--start-from', type=int, default=0,
                        help='Start from prompt index (0-based)')
    parser.add_argument('--delay', type=int, default=30,
                        help='Seconds to wait between prompts (default: 30)')
    parser.add_argument('--timeout', type=int, default=180,
                        help='Max seconds to wait for image generation (default: 180)')
    parser.add_argument('--port', type=int, default=9222,
                        help='Chrome debug port (default: 9222)')
    parser.add_argument('--debug', action='store_true',
                        help='Print CDP debug messages')
    parser.add_argument('--list', action='store_true',
                        help='List all prompts and exit')
    args = parser.parse_args()

    if args.list:
        for i, p in enumerate(build_prompts()):
            print(f"  {i:2d}. {p['filename']}")
        return

    automator = GeminiAutomator(port=args.port, debug=args.debug)
    try:
        await automator.connect()
        await automator.run(
            output_dir=args.output_dir,
            start_from=args.start_from,
            delay=args.delay,
            timeout=args.timeout,
        )
    finally:
        await automator.close()


if __name__ == '__main__':
    asyncio.run(main())
