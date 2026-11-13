#!/usr/bin/env python3
"""Original pixel source for Combat Lab v054. Pillow is an authoring tool only.
No reference image is read. All coordinates are source pixels; runtime uses PNGs.
"""
from pathlib import Path
import json
import math
import random
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/combat_v054'
OUT.mkdir(parents=True, exist_ok=True)
INK = '#171c26'
STONE = ['#242730', '#323137', '#403b3c', '#51483f', '#6c5c4b', '#8b7861']
WOOD = ['#32232a', '#53342c', '#7e4d32', '#a46b3d', '#ce9756']
METAL = ['#303641', '#52606a', '#85919a', '#c5ccd0']
BONE = ['#695a4b', '#a49375', '#d5c39b', '#f1e1b8']
MOSS = ['#2d3927', '#46542b', '#6b7131', '#93904b']
manifest = {'schema_version': 1, 'source_pixels_per_cell': 32, 'display_art_pixels': 64,
            'board_pitch': 68, 'filter': 'nearest', 'provenance': 'Original coordinate-authored pixel art; scripts/build_combat_art.py; no reference pixels used.',
            'license': 'Project-original; same license as repository original artwork (docs/licensing.md).', 'assets': {}}

def canvas(w=32, h=32):
    im = Image.new('RGBA', (w,h)); return im, ImageDraw.Draw(im)

def save(name, im, **meta):
    im.save(OUT / (name + '.png'))
    manifest['assets'][name] = dict(file=name+'.png', size=list(im.size), **meta)

def poly(d, pts, fill, outline=INK):
    d.polygon(pts, fill=fill)
    if outline: d.line(pts+[pts[0]], fill=outline, width=1)

def rock(d, x, y, w, h, seed=1):
    rng=random.Random(seed)
    poly(d, [(x,y+h//3),(x+w//4,y),(x+3*w//4,y+1),(x+w,y+h//3),(x+w-1,y+4*h//5),(x+w//2,y+h),(x+1,y+4*h//5)], STONE[2])
    poly(d, [(x+1,y+h//3),(x+w//4,y+1),(x+3*w//4,y+2),(x+w-1,y+h//3),(x+w//2,y+h//2)], STONE[4], None)
    poly(d, [(x+w//2,y+h//2),(x+w-1,y+h//3),(x+w-2,y+4*h//5),(x+w//2,y+h-1)], STONE[1], None)
    d.line([(x+2,y+h//3),(x+w//4,y+2),(x+3*w//4,y+3)],fill=STONE[5])
    d.line([(x+w//2,y+h//2),(x+w//2-1,y+h-2)],fill=STONE[0])
    for _ in range(w*h//16):
        px=rng.randint(x+2,x+max(2,w-2)); py=rng.randint(y+2,y+max(2,h-2))
        d.point((px,py), fill=rng.choice(STONE[2:5]))

def wood_box(d, box):
    x,y,r,b=box
    d.rectangle(box,fill=WOOD[1],outline=INK)
    for px in range(x+2,r,4):
        d.line((px,y+1,px,b-1),fill=WOOD[2]); d.line((px+1,y+1,px+1,b-1),fill=WOOD[3])
    d.line((x+1,y+1,r-1,y+1),fill=WOOD[4])
    d.line((x+1,b-1,r-1,b-1),fill=WOOD[0])

# Floor boundaries have identical sample values on every variant and opposite edge.
floors=Image.new('RGBA',(32*8,32))
for v in range(8):
    im,d=canvas(); rng=random.Random(540+v)
    d.rectangle((0,0,31,31),fill=STONE[1])
    for y in range(1,31):
        for x in range(1,31):
            d.point((x,y),fill=rng.choice([STONE[1]]*18+[STONE[2]]*3+[STONE[0]]))
    for _ in range(14):
        x=rng.randint(2,26); y=rng.randint(2,26); w=rng.randint(2,5); h=rng.randint(1,3)
        poly(d,[(x,y+1),(x+1,y),(x+w,y),(x+w,y+h),(x+1,y+h+1)],rng.choice(STONE[2:4]),None)
        d.line((x+1,y,x+w-1,y),fill=STONE[3])
    if v in (3,4):
        for _ in range(40):
            x=rng.randrange(3,28); y=rng.randrange(3,28)
            if (x-15)**2+(y-15)**2<130: d.rectangle((x,y,x+1,y),fill=rng.choice(MOSS))
    if v==5:
        d.line([(4,8),(10,12),(12,18),(22,23),(26,29)],fill=INK)
        d.line([(10,12),(19,10),(23,6)],fill=INK)
    if v==6:
        for _ in range(5): rock(d,rng.randint(3,22),rng.randint(4,22),5,4,_)
    if v==7:
        d.line([(5,23),(10,25),(23,25),(27,21)],fill='#64787c')
        d.line([(8,23),(15,24),(23,22)],fill='#3e5963')
    # Common boundary samples across all variants prevent cracks/colour jumps.
    d.rectangle((0,0,31,31),outline=STONE[1])
    floors.paste(im,(v*32,0))
save('terrain',floors,frame_size=[32,32],frames=8,seam='All floor variant/opposite boundaries equal',ids=['stone_a','stone_b','stone_c','moss_a','moss_b','cracked','rubble','wet'])
# Sixteen neighbor-mask wall tiles: N/E/S/W bits. Open edges have rocky faces.
walls=Image.new('RGBA',(32*16,48))
for mask in range(16):
    im,d=canvas(32,48)
    d.rectangle((0,16,31,46),fill=STONE[0])
    for i in range(4):
        x=i*8
        poly(d,[(x,12),(x+4,8),(x+9,12),(x+8,42),(x+4,47),(x,43)],STONE[1])
        d.line((x+1,18,x+1,39),fill=STONE[3]);d.line((x+7,22,x+7,44),fill=INK)
        rock(d,x,8,8,14,mask*10+i)
    if mask & 1: d.rectangle((0,0,31,10),fill=STONE[2])
    if mask & 2: d.rectangle((27,9,31,25),fill=STONE[2])
    if mask & 8: d.rectangle((0,9,4,25),fill=STONE[2])
    if mask & 4:
        for i in range(4): rock(d,i*8,25,8,18,mask+i)
    if mask%3==0:
        for x,y in [(2,23),(4,28),(6,25),(25,18),(26,23)]:
            d.rectangle((x,y,x+2,y+2),fill=MOSS[1]);d.point((x,y),fill=MOSS[3])
    walls.paste(im,(mask*32,0))
save('walls',walls,frame_size=[32,48],frames=16,neighbor_bits={'north':1,'east':2,'south':4,'west':8},height_offset=16,collision='fixture walls only')
# Transparent decorative ground transition masks, seamless alpha edges.
decals=Image.new('RGBA',(32*8,32))
for v in range(8):
    im,d=canvas();rng=random.Random(700+v)
    if v<4:
        for _ in range(60):
            x=rng.randrange(2,30);y=rng.randrange(2,30)
            if y < 8+int(4*math.sin(x/4)): d.rectangle((x,y,x+1,y+1),fill=rng.choice(MOSS))
        if v: im=im.rotate(v*90)
    elif v==4:
        for k in range(9): rock(d,rng.randrange(2,24),rng.randrange(3,24),rng.randrange(3,7),4,k)
    else:
        for k in range(10):
            x=rng.randrange(3,27);y=rng.randrange(3,27);d.line((x,y,x+3,y),fill='#61767a80')
    decals.paste(im,(v*32,0))
save('decals',decals,frame_size=[32,32],frames=8,ids=['moss_n','moss_e','moss_s','moss_w','rubble','wet_a','wet_b','wet_c'],collision='none')
# Props use source pixel footprints and extra upper headroom.
im,d=canvas(96,80)
d.ellipse((5,65,92,78),fill='#0e141b85')
wood_box(d,(9,39,89,65))
for y in (43,53,62): d.line((10,y,88,y),fill=WOOD[0])
# Canvas barrel roof, open front and illuminated ribs.
poly(d,[(10,44),(10,23),(15,14),(25,8),(71,8),(83,14),(89,24),(89,47)],'#9b8057')
poly(d,[(13,43),(13,24),(19,16),(27,13),(74,13),(83,21),(86,44)],'#c9ad79')
for x in (28,44,60,76):
    d.line([(x,10),(x+5,18),(x+7,28),(x+7,44)],fill='#816543',width=2)
    d.line([(x+2,11),(x+7,19),(x+9,29),(x+9,43)],fill='#ead09a')
poly(d,[(10,44),(10,24),(15,16),(20,13),(25,17),(28,27),(28,44)],WOOD[0])
poly(d,[(13,42),(13,25),(17,18),(20,17),(24,26),(25,42)],'#1d2324')
d.line([(11,42),(11,24),(16,16),(20,14),(25,19)],fill='#ecd4a1')
wood_box(d,(7,43,29,57)); d.rectangle((11,44,19,48),fill=MOSS[1])
for x in (27,73):
    d.ellipse((x-9,55,x+9,75),fill=WOOD[0],outline=INK)
    d.ellipse((x-7,57,x+7,73),fill=WOOD[2],outline=WOOD[4])
    for a in range(0,360,45):
        xx=x+int(6*math.cos(math.radians(a)));yy=65+int(7*math.sin(math.radians(a)))
        d.line((x,65,xx,yy),fill=WOOD[4])
    d.ellipse((x-2,63,x+2,67),fill=METAL[1],outline=INK)
# Frayed hem, canvas folds, muted stains and light on raised ribs.
for x in range(31,85):
    y=41+(x%5==0)
    d.point((x,y),fill='#ead09a' if x%3 else '#8d714f')
    if x%4==0:d.point((x,38),fill='#ad9062')
for x,y in [(35,22),(38,31),(49,17),(53,35),(64,27),(69,19),(78,34)]:
    d.line((x,y,x+2,y),fill='#b99a68');d.point((x+1,y+1),fill='#bfa16d')
for x in (29,45,61,77):
    d.line([(x+3,13),(x+6,20),(x+8,29),(x+8,38)],fill='#f1d9a3')
    for y in range(23,39,4):d.point((x+6,y),fill='#765c41')
for y in (46,56,61):
    for x in range(33,84,7):
        d.line((x,y,x+4,y),fill=WOOD[3]);d.point((x+2,y+1),fill=WOOD[0])
for x in range(32,86,9):
    d.rectangle((x,47,x+2,49),fill=METAL[1]);d.point((x,47),fill=METAL[3])
d.line((32,52,85,52),fill=WOOD[4]);d.line((32,64,85,64),fill=WOOD[0])
# Supply rail and sack in the open back.
d.line((6,44,28,44),fill=WOOD[4]);d.line((6,52,28,52),fill=WOOD[3])
for x in (8,17,26):d.line((x,44,x,56),fill=WOOD[0],width=2);d.point((x,46),fill=METAL[2])
save('wagon',im,footprint=[3,2],pivot=[48,76],height_offset=16,cover='total',collision='fixture')
im,d=canvas(32,80);d.ellipse((2,68,30,78),fill='#10141c99')
rock(d,3,35,25,41,2);rock(d,5,16,23,35,4);rock(d,2,48,16,26,6)
for x,y in [(6,34),(8,38),(24,59)]:d.rectangle((x,y,x+2,y+2),fill=MOSS[1]);d.point((x,y),fill=MOSS[3])
save('boulder',im,footprint=[1,2],pivot=[16,76],height_offset=16,cover='total',collision='fixture')
for name in ['chest','crate','barrel','table','campfire']:
    w,h=(64,72) if name=='table' else (32,40)
    im,d=canvas(w,h);d.ellipse((2,h-10,w-2,h-2),fill='#10141c80')
    if name=='chest':
        wood_box(d,(4,20,28,33));poly(d,[(4,20),(7,14),(24,14),(28,20)],WOOD[3])
        d.line((8,15,23,15),fill=WOOD[4])
        for x in (7,23):d.rectangle((x,17,x+2,32),fill=METAL[1]);d.line((x,18,x,31),fill=METAL[2])
        d.rectangle((14,22,18,27),fill='#dfb663',outline=INK);d.point((16,24),fill=INK)
    elif name=='crate':
        wood_box(d,(5,12,27,33));d.line((7,14,25,31),fill=WOOD[4],width=3);d.line((25,14,7,31),fill=WOOD[3],width=3)
        for x,y in [(7,14),(25,14),(7,31),(25,31)]:d.point((x,y),fill=METAL[2])
    elif name=='barrel':
        poly(d,[(9,9),(23,9),(27,16),(27,28),(23,34),(9,34),(5,28),(5,16)],WOOD[2])
        for x in range(9,25,4):d.line((x,12,x,31),fill=WOOD[4])
        for y in (15,27):d.rectangle((6,y,26,y+2),fill=METAL[1]);d.line((7,y,25,y),fill=METAL[2])
        d.ellipse((8,8,24,14),fill=WOOD[0],outline=WOOD[4]);d.line((11,11,22,11),fill=WOOD[2])
    elif name=='table':
        for x in (7,50):wood_box(d,(x,40,x+6,65))
        wood_box(d,(4,16,60,48));d.line((5,49,60,49),fill=WOOD[0],width=2)
    else:
        for k in range(9):
            a=k*math.tau/9;rock(d,13+int(10*math.cos(a)),26+int(4*math.sin(a)),6,5,k)
        d.line((10,27,24,32),fill=WOOD[2],width=3);d.line((23,26,10,32),fill=WOOD[3],width=3)
        d.rectangle((13,28,21,30),fill='#e27233')
    save(name,im,footprint=[2,2] if name=='table' else [1,1],pivot=[w//2,h-4],height_offset=h-(64 if name=='table' else 32),cover='half' if name in ['chest','table'] else 'fixture',collision='fixture' if name!='campfire' else 'walkable hazard')
# Monsters: nine named states in horizontal boxes, four equipment/facing rows.
# Draw each facing anatomically: shield stays on near arm, weapon on far arm;
# neither canvas nor asymmetric equipment is mirrored.
states=['idle_0','idle_1','walk_0','walk_1','walk_2','melee_0','melee_1','hit','defeated','ranged_0','ranged_1']
for species in ['goblin','kobold','bugbear','spider','skeleton']:
    species_states=states if species in ['goblin','kobold'] else states[:9]
    rows=4 if species in ['goblin','kobold'] else 2
    sheet=Image.new('RGBA',(48*len(species_states),48*rows))
    for row in range(rows):
        facing=-1 if row%2==0 else 1; ranged=row>=2
        for col,state in enumerate(species_states):
            im,d=canvas(48,48);rng=random.Random(1100+col)
            cx=24; bob=1 if state in ['idle_1','walk_1'] else 0
            cy=22+bob;step={'walk_0':-3,'walk_1':0,'walk_2':3}.get(state,0)
            skin={'goblin':['#45522c','#74813e','#a1a953'], 'kobold':['#763831','#ae5536','#db8050'], 'bugbear':['#5b3b2d','#946039','#c78a4b'],'spider':['#302b40','#59415b','#866079'],'skeleton':BONE[1:]}[species]
            if state=='defeated':
                if species=='spider':
                    for k in range(4):d.line([(9+k*7,37),(15+k*5,30),(22,35)],fill=skin[1],width=2)
                    d.ellipse((17,28,34,37),fill=skin[0],outline=INK)
                else:
                    d.ellipse((10,29,32,37),fill=WOOD[1] if species!='skeleton' else BONE[0],outline=INK)
                    d.ellipse((29,27,39,35),fill=skin[1],outline=INK);d.line((8,36,26,38),fill=skin[1],width=3)
                    d.line((33,31,35,33),fill=INK)
                sheet.paste(im,(col*48,row*48));continue
            if species=='spider':
                for k in range(4):
                    y=24+k*3
                    for side in (-1,1):
                        tip=6 if k%2==0 else 9
                        lift=step if k%2 else -step
                        d.line([(24+side*5,y),(24+side*(12+k),y-5),(24+side*(17-k),36+lift)],fill=INK,width=4)
                        d.line([(24+side*5,y),(24+side*(12+k),y-5),(24+side*(17-k),36+lift)],fill=skin[1],width=2)
                        d.point((24+side*(12+k),y-5),fill=skin[2])
                d.ellipse((15,12+bob,34,30+bob),fill=skin[0],outline=INK)
                d.ellipse((17,13+bob,29,23+bob),fill=skin[1])
                hx=24+facing*6
                d.ellipse((hx-6,23,hx+6,33),fill=skin[1],outline=INK)
                for dx in (-3,1):d.rectangle((hx+dx,26,hx+dx+1,27),fill='#eb714f')
                for dx in (-3,3):d.line((hx+dx,31,hx+dx+facing*2,36 if state=='melee_1' else 33),fill=BONE[2])
            else:
                bulk=4 if species=='bugbear' else 0
                # boots and legs grounded to y=40 across all locomotion states
                for side in (-1,1):
                    x=cx+side*(4+bulk//2)+side*step
                    d.line((cx+side*4,30,x,38),fill=INK,width=5)
                    d.line((cx+side*4,30,x,38),fill=skin[0] if species=='skeleton' else WOOD[2],width=3)
                    d.rectangle((x-2,38,x+3,40),fill=WOOD[0] if species!='skeleton' else BONE[1])
                    d.line((x-1,38,x+2,38),fill=WOOD[3] if species!='skeleton' else BONE[2])
                poly(d,[(cx-6-bulk,cy-1),(cx+5+bulk,cy-1),(cx+7+bulk,32),(cx-6-bulk,32)],WOOD[1] if species!='skeleton' else INK)
                if species=='skeleton':
                    d.line((cx,cy,cx,32),fill=BONE[2],width=2)
                    for y in range(cy+1,30,3): d.line((cx-5,y,cx+5,y),fill=BONE[1]);d.point((cx-4,y),fill=BONE[3])
                else:
                    d.line((cx-5,cy,cx+4,31),fill=WOOD[3],width=3)
                    d.line((cx-7-bulk,31,cx+6+bulk,31),fill=WOOD[0],width=2)
                    d.rectangle((cx,30,cx+2,32),fill='#d3ae60')
                hx=cx+facing*2;hy=cy-12
                d.ellipse((hx-6-bulk//2,hy,hx+6+bulk//2,cy+1),fill=skin[0],outline=INK)
                d.ellipse((hx-5,hy+1,hx+4,cy-2),fill=skin[1]);d.line((hx-3,hy+2,hx+2,hy+2),fill=skin[2])
                if species in ['goblin','bugbear']:
                    for side in (-1,1):poly(d,[(hx+side*5,hy+3),(hx+side*11,hy+1),(hx+side*6,hy+7)],skin[1])
                if species=='kobold':
                    poly(d,[(hx+facing*3,hy+5),(hx+facing*10,hy+6),(hx+facing*9,hy+10),(hx+facing*2,hy+10)],skin[1])
                    d.line([(cx-5*facing,31),(cx-12*facing,34),(cx-15*facing,30)],fill=skin[1],width=2)
                    d.line((hx-3,hy+1,hx-4,hy-3),fill=BONE[1]);d.line((hx+2,hy+1,hx+3,hy-2),fill=BONE[1])
                if species!='skeleton':
                    d.line((hx-4,hy+3,hx-3,hy+6),fill=skin[2])
                    d.line((hx-2,hy+9,hx+2,hy+10),fill=skin[0])
                    d.point((hx+facing*5,hy+9),fill=BONE[2])
                    d.point((hx+facing*3,hy+11),fill=BONE[1])
                    for xx,yy in [(cx-3,cy+2),(cx+1,cy+5),(cx+3,cy+8)]:d.point((xx,yy),fill=WOOD[4])
                    d.line((cx-4,cy+2,cx-5,cy+7),fill=WOOD[2])
                    d.line((cx+4,cy+4,cx+5,cy+9),fill=WOOD[0])
                else:
                    d.line((hx-4,hy+8,hx+3,hy+9),fill=BONE[0])
                    for xx in range(hx-3,hx+4,2):d.point((xx,hy+11),fill=BONE[3])
                    d.rectangle((hx-4,hy+5,hx-2,hy+7),fill=INK)
                eye=hx+facing*3
                d.rectangle((eye-1,hy+5,eye+1,hy+7),fill=INK);d.point((eye,hy+5),fill='#efc364' if species!='skeleton' else '#2c2525')
                d.line((hx+facing*2,hy+10,hx+facing*6,hy+10),fill=INK)
                # Near arm stays screen-left; separate authored weapon positions per facing.
                d.line((cx-6-bulk,cy+1,cx-8-bulk,29),fill=INK,width=5)
                d.line((cx-6-bulk,cy+1,cx-8-bulk,29),fill=skin[1],width=3)
                if not ranged and species in ['goblin','skeleton']:
                    poly(d,[(cx-13,cy+2),(cx-6,cy+1),(cx-5,cy+10),(cx-10,cy+13),(cx-14,cy+9)],WOOD[2],METAL[1])
                    d.line((cx-10,cy+3,cx-10,cy+10),fill=METAL[2])
                handx=cx+facing*(9+bulk);handy=cy+6
                if state in ['melee_1','ranged_1']:handx+=facing*5;handy-=3
                if state=='melee_0':handy-=9
                handx=max(12,min(35,handx))
                d.line((cx+5*facing,cy+1,handx,handy),fill=INK,width=5);d.line((cx+5*facing,cy+1,handx,handy),fill=skin[1],width=3)
                if ranged:
                    if species=='kobold':
                        d.line([(handx,handy),(handx+facing*5,handy-9),(handx+facing*8,handy-5)],fill=WOOD[4])
                        d.ellipse((handx+facing*5-1,handy-10,handx+facing*5+1,handy-8),fill=STONE[4])
                    else:
                        bowx=handx+facing*3
                        d.line([(bowx-facing*2,handy-10),(bowx+facing*3,handy-5),(bowx+facing*3,handy+3),(bowx-facing*2,handy+8)],fill=WOOD[4],width=2)
                        d.line((bowx-facing*2,handy-10,bowx-facing*2,handy+8),fill=BONE[1])
                        d.line((handx-facing*5,handy,bowx+facing*5,handy),fill=METAL[2])
                elif species=='bugbear':
                    d.line((handx,handy,handx+facing*3,handy-10),fill=WOOD[3],width=2)
                    d.ellipse((handx+facing*3-4,handy-15,handx+facing*3+4,handy-7),fill=METAL[1],outline=INK)
                    for dx,dy in [(-4,-11),(4,-11),(0,-15)]:d.point((handx+facing*3+dx,handy+dy),fill=METAL[3])
                else:
                    tipx=handx+facing*(9 if state=='melee_1' else 4);tipy=handy-(3 if state=='melee_1' else 10)
                    tipx=max(4,min(43,tipx))
                    d.line((handx,handy,tipx,tipy),fill=INK,width=4);d.line((handx,handy,tipx,tipy),fill=METAL[2],width=2);d.point((tipx,tipy),fill=METAL[3])
                if state=='hit':
                    d.line((cx+8,hy,cx+10,hy-3),fill='#e78368');d.line((cx+11,hy+3,cx+14,hy+2),fill='#ffd08c')
            sheet.paste(im,(col*48,row*48))
    animations={ 'idle':{'frames':[0,1],'frame_ms':420,'loop':True}, 'walk':{'frames':[2,3,4],'frame_ms':100,'loop':True}, 'melee':{'frames':[5,6],'frame_ms':140,'loop':False}, 'hit':{'frames':[7],'frame_ms':200,'loop':False}, 'defeated':{'frames':[8],'frame_ms':1000,'loop':False}}
    if species in ['goblin','kobold']:animations['ranged']={'frames':[9,10],'frame_ms':170,'loop':False}
    save(species,sheet,frame_size=[48,48],pivot=[24,41],rows=['melee_left','melee_right','ranged_left','ranged_right'][:rows],states=species_states,animations=animations,ranged_equipment={'goblin':'shortbow','kobold':'sling'}.get(species),integration='asset only; no new stat block' if species=='bugbear' else 'existing monster')
# Separate four-frame effects, no baked actors or labels.
names=['flame','smoke','ember','web','burning_web','fire_bolt','magic_missile','frost','bless','healing','shield','radiant','impact','arcane','slash','arrow','sling']
vfx=Image.new('RGBA',(32*4,32*len(names)))
for row,name in enumerate(names):
    for f in range(4):
        im,d=canvas();rng=random.Random(300+f)
        if name in ['web','burning_web']:
            color='#b7c9cdad' if name=='web' else '#de9b5abd'
            for k in range(8):
                a=k*math.tau/8;x=16+int(14*math.cos(a));y=16+int(14*math.sin(a));d.line((16,16,x,y),fill=color)
            for r in (4,8,12):
                points=[(16+int((r+(k%2))*math.cos(k*math.tau/8)),16+int((r+(k%2))*math.sin(k*math.tau/8))) for k in range(8)]
                d.line(points+[points[0]],fill=color)
            if name=='burning_web':
                for k in range(5):
                    x=rng.randrange(5,27);y=rng.randrange(7,27);d.line((x,y,x+1,y-3),fill='#f7bf59');d.point((x,y-4),fill='#e46b32')
        elif name=='flame':
            for x,y,h in [(8,28,9+f%2*3),(13,29,18-f),(19,29,12+f),(24,28,8+f)]:
                poly(d,[(x-4,y),(x-3,y-5),(x+1,y-h),(x+3,y-6),(x+4,y)],'#c65b2d',None)
                poly(d,[(x-2,y),(x,y-h+5),(x+2,y-3)],'#f4a33e',None)
                d.line((x,y-1,x+1,y-5),fill='#ffe6a0')
        elif name=='smoke':
            for k in range(3):
                x=12+int(4*math.sin(k+f));y=24-k*7-f; r=3+k
                d.ellipse((x-r,y-r,x+r,y+r),fill=(99+k*8,99+k*8,109+k*8,65-k*12))
        elif name=='ember':
            for k in range(4):
                x=7+(k*7+f*3)%20;y=28-(k*6+f*4)%25;d.point((x,y),fill='#efb45e');d.point((x,y+1),fill='#bd5b32')
        elif name in ['fire_bolt','magic_missile','frost','arrow','sling']:
            if name=='arrow':
                d.line((4,16,27,16),fill=WOOD[4]);poly(d,[(27,13),(30,16),(27,19)],METAL[3],None);d.line((5,13,8,16),fill=BONE[1]);d.line((5,19,8,16),fill=BONE[1])
            elif name=='sling':
                d.line((6,16,20,16),fill='#98867477');rock(d,22,13,6,6,1)
            else:
                c={'fire_bolt':['#b94425','#f19335','#ffe7a1'],'magic_missile':['#644488','#ad79d1','#f2daff'],'frost':['#355e83','#7bb9cb','#d2f7ed']}[name]
                for k in range(5):
                    x=5+k*4;y=16+int(math.sin(k+f)*2);d.line((x-3,y,x+3,y),fill=c[0],width=3)
                d.ellipse((20,11,29,20),fill=c[1]);d.line((22,15,28,15),fill=c[2],width=2)
                if name=='frost':
                    d.line((24,9,24,23),fill=c[2]);d.line((19,10,29,21),fill=c[1])
                for k in range(4):d.point((rng.randrange(3,24),rng.randrange(8,23)),fill=c[1])
        elif name in ['bless','healing','shield','arcane']:
            c={'bless':('#e3b660','#ffedb5'),'healing':('#64b57a','#c8f3a1'),'shield':('#6498bf','#d5eff6'),'arcane':('#987cba','#e5c8f5')}[name]
            d.arc((4,21-f%2,28,29),0,350,fill=c[0]);d.arc((7,22,25,27),0,350,fill=c[1])
            for k in range(5):
                x=6+(k*5+f*3)%22;y=25-(k*5+f*3)%21
                d.line((x,y-1,x,y+1),fill=c[1]);d.line((x-1,y,x+1,y),fill=c[0])
            if name=='healing':
                d.rectangle((15,8,17,18),fill=c[1]);d.rectangle((11,12,21,14),fill=c[1])
            if name=='bless':d.line((16,5,16,20),fill=c[1]);d.line((12,10,20,10),fill=c[0])
            if name=='shield':poly(d,[(10,8),(16,5),(23,8),(22,19),(16,24),(10,19)],'#6794be55',c[1])
        elif name=='slash':
            d.arc((4-f,3,28,28+f),230,340,fill=METAL[3],width=2)
        else:
            c='#ffe8ac' if name=='radiant' else '#e9c8ae'
            for k in range(8):
                a=k*math.tau/8;r=4+f*3
                d.line((16+int(3*math.cos(a)),16+int(3*math.sin(a)),16+int(r*math.cos(a)),16+int(r*math.sin(a))),fill=c)
            d.ellipse((14,14,18,18),fill='#fff4d3')
        vfx.paste(im,(f*32,row*32))
save('vfx',vfx,frame_size=[32,32],frames=4,frame_ms=140,rows=names,pivot=[16,28],collision='none; cosmetic only')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(f'Authored {len(manifest["assets"])} original PNG assets')

# Native SpriteFrames resources make the atlases directly usable in AnimatedSprite2D.
for name,meta in manifest['assets'].items():
    if 'animations' not in meta and name!='vfx': continue
    fw,fh=meta['frame_size']; cols=meta['size'][0]//fw; rows=meta['size'][1]//fh
    lines=[f'[gd_resource type="SpriteFrames" load_steps={cols*rows+2} format=3]', '', f'[ext_resource type="Texture2D" path="res://assets/combat_v054/{name}.png" id="1"]', '']
    for row in range(rows):
        for col in range(cols):
            index=row*cols+col+1
            lines.extend([f'[sub_resource type="AtlasTexture" id="Atlas_{index}"]', 'atlas = ExtResource("1")', f'region = Rect2({col*fw}, {row*fh}, {fw}, {fh})', 'filter_clip = true', ''])
    animations=[]
    for row,label in enumerate(meta['rows']):
        states=meta.get('animations', {label:{'frames':list(range(cols)), 'frame_ms':meta['frame_ms'], 'loop':True}}) if name=='vfx' else meta['animations']
        for state,anim in states.items():
            if name!='vfx' and state=='ranged' and row<2:continue
            if name!='vfx' and state=='melee' and row>=2:continue
            sequence=', '.join('{"duration": 1.0, "texture": SubResource("Atlas_%d")}'%(row*cols+f+1) for f in anim['frames'])
            key=label if name=='vfx' else label+'_'+state
            animations.append('{"frames": ['+sequence+'], "loop": '+str(anim['loop']).lower()+', "name": &"'+key+'", "speed": '+str(1000/anim['frame_ms'])+'}')
    lines.extend(['[resource]', 'animations = ['+',\n'.join(animations)+']', ''])
    (OUT/(name+'.tres')).write_text('\n'.join(lines))
