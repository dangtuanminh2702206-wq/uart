from pathlib import Path
import hashlib,csv,zipfile
root=Path(__file__).resolve().parents[1]
selected=[]
for p in root.rglob('*'):
 if not p.is_file():continue
 rel=p.relative_to(root).as_posix()
 if rel=='SHA256SUMS.csv' or p.suffix in ['.dat','.pem','.vvp','.zip']:continue
 if rel.startswith('build/unlicensed_artifacts/'):continue
 if rel.startswith('build/') and p.suffix not in ['.log','.txt']:continue
 if rel.startswith('nios_system/') and ('/simulation/' in rel or p.suffix in ['.spd','.html']):continue
 if rel.endswith('probe_system.tcl') or rel.startswith('ip/'):continue
 if rel in ['core/master/apb_echo_master.v','core/top/uart_apb_echo_system.v','core/board/de2_115_apb_echo_top.v']:continue
 selected.append(p)
with (root/'SHA256SUMS.csv').open('w',newline='',encoding='utf-8') as f:
 w=csv.writer(f);w.writerow(['path','sha256','size'])
 for p in sorted(selected):
  b=p.read_bytes();w.writerow([p.relative_to(root).as_posix(),hashlib.sha256(b).hexdigest(),len(b)])
archive=root.parent/'UART_APB_NIOS_PREPARED.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
 for p in selected+[root/'SHA256SUMS.csv']:z.write(p,p.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for r in csv.DictReader(z.read('SHA256SUMS.csv').decode().splitlines()):assert hashlib.sha256(z.read(r['path'])).hexdigest()==r['sha256']
print('PASS project package CRC and manifest hashes:',archive)
