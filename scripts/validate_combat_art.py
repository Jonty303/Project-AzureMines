#!/usr/bin/env python3
"""Validate shipped pixels/metadata without modifying or sampling references."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
ART = ROOT/'assets/combat_v054'

def main():
    manifest=json.loads((ART/'manifest.json').read_text())
    frame_count=0
    for name,meta in manifest['assets'].items():
        image=Image.open(ART/meta['file'])
        assert image.mode=='RGBA' and list(image.size)==meta['size'],name
        fw,fh=meta.get('frame_size',image.size)
        assert image.width%fw==0 and image.height%fh==0,name
        if 'pivot' in meta:
            x,y=meta['pivot'];assert 0<=x<fw and 0<=y<fh,name
        for y in range(0,image.height,fh):
            for x in range(0,image.width,fw):
                frame=image.crop((x,y,x+fw,y+fh))
                assert frame.getbbox(),f'{name}: empty frame {x},{y}'
                if name in ['goblin','kobold','bugbear','spider','skeleton']:
                    alpha=frame.getchannel('A')
                    assert not alpha.crop((0,0,fw,2)).getbbox(),f'{name}: top weapon cut off'
                    assert not alpha.crop((0,fh-2,fw,fh)).getbbox(),f'{name}: feet cut off'
                    assert not alpha.crop((0,0,2,fh)).getbbox(),f'{name}: left weapon cut off'
                    assert not alpha.crop((fw-2,0,fw,fh)).getbbox(),f'{name}: right weapon cut off'
                frame_count+=1
        if 'animations' in meta:
            for state in ['idle','walk','melee','hit','defeated']:
                assert state in meta['animations']
            assert len(meta['animations']['walk']['frames']) in [2,3]
            assert len(meta['animations']['melee']['frames'])==2
            for anim in meta['animations'].values():
                assert anim['frame_ms']>0
                assert all(0<=f<image.width//fw for f in anim['frames'])
            assert len(meta['rows'])==image.height//fh
    terrain=Image.open(ART/'terrain.png')
    boundary=None
    for i in range(8):
        tile=terrain.crop((32*i,0,32*(i+1),32))
        edges=[tile.crop(box).tobytes() for box in [(0,0,1,32),(31,0,32,32),(0,0,32,1),(0,31,32,32)]]
        assert all(e==edges[0] for e in edges),'opposite seams'
        assert boundary is None or boundary==edges[0],'variant seams'
        boundary=edges[0]
    for name in ['wagon','boulder','chest']:
        image=Image.open(ART/(name+'.png'))
        assert image.getchannel('A').getextrema()==(0,255),name+' alpha'
    print(f'PASS: {len(manifest["assets"])} RGBA PNGs; {frame_count} nonempty frames; monster gutters/pivots/states, prop alpha and all 8x8 floor boundary pairings')

if __name__=='__main__':main()
