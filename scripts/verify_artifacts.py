"""Verify actual bundled audio and package deliverables; no network needed."""
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'assets/library.json').read_text(encoding='utf-8'))
ids = set()
for song in manifest:
    assert song['id'] not in ids, 'duplicate music ID'
    ids.add(song['id'])
    asset = root / song['asset']
    assert asset.resolve().is_relative_to((root / 'assets/music').resolve())
    data = asset.read_bytes()
    assert len(data) == song['bytes']
    assert hashlib.sha256(data).hexdigest() == song['sha256']
    assert data[:3] == b'ID3' or data[0] == 0xff, 'not an MP3'
print(f'Verified {len(manifest)} real bundled MP3 file(s)')

if __name__ == '__main__':
    dist = root / 'dist'
    dist.mkdir(exist_ok=True)
    apk = root / 'build/app/outputs/flutter-apk/app-release.apk'
    if apk.exists():
        target = dist / 'little-music-testing.apk'
        shutil.copyfile(apk, target)
        with zipfile.ZipFile(target) as archive:
            for song in manifest:
                assert archive.read('assets/flutter_assets/' + song['asset']) == (root / song['asset']).read_bytes()
        print('APK packaged with byte-identical approved music')
    web = root / 'build/web'
    if (web / 'index.html').exists():
        target = dist / 'little-music-web.zip'
        with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
            for file in sorted(web.rglob('*')):
                if file.is_file():
                    archive.write(file, file.relative_to(web).as_posix())
        with zipfile.ZipFile(target) as archive:
            assert 'index.html' in archive.namelist()
            for song in manifest:
                assert archive.read('assets/' + song['asset']) == (root / song['asset']).read_bytes()
        print('Web ZIP verified: index at root and byte-identical approved music')
    checksums = []
    for file in sorted(dist.glob('*')):
        if file.suffix in ('.apk', '.zip', '.ipa'):
            sha = hashlib.sha256(file.read_bytes()).hexdigest()
            checksums.append(f'{sha}  {file.name}\n')
            print(file.name, file.stat().st_size, sha)
    (dist / 'SHA256SUMS.txt').write_text(''.join(checksums), encoding='utf-8')
