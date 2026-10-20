#!/usr/bin/env python3
"""Render BibleQuest's two arrangements from CC0 VSCO 2 CE samples.
Python 3.12; numpy, scipy, soundfile; macOS afconvert for AAC export.
Only selected samples are downloaded, pinned to the manifest commit.
No movie audio, commercial recordings, generated vocals or soundfont banks.
"""
from pathlib import Path
from fractions import Fraction
import argparse,functools,json,math,re,subprocess,urllib.parse,urllib.request
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly,fftconvolve,butter,sosfilt

ROOT=Path(__file__).resolve().parents[2]
SR=44100
NOTES={'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}
def midi(s):
 m=re.fullmatch(r'([A-G])([#b]?)(\d)',s);return (int(m[3])+1)*12+NOTES[m[1]]+({'#':1,'b':-1,'':0}[m[2]])

def main(cache):
 manifest=json.loads((ROOT/'docs/rain-orchestra-music-samples.json').read_text());cache=Path(cache)
 sources={}
 for path in manifest['samples']:
  dest=cache/path;dest.parent.mkdir(parents=True,exist_ok=True)
  if not dest.exists():urllib.request.urlretrieve('https://raw.githubusercontent.com/sgossner/VSCO-2-CE/'+manifest['commit']+'/'+urllib.parse.quote(path),dest)
  key=('flute' if 'Flute/' in path else 'pizz' if '/Pizz/' in path else 'strings' if '/susVib/' in path else 'cello' if '/pizzT/' in path else 'harp' if '/Harp/' in path else 'glock' if '/Glock/' in path else 'marimba' if '/Marimba/' in path else 'shaker' if 'maraca' in path else 'tambourine')
  match=re.search(r'_([A-G]#?\d)_',dest.name) or re.search(r'_([A-G]#?\d)\.',dest.name)
  # VSCO uses C3=middle C, except the harp's scientific-pitch file names.
  pitch=midi(match[1])+(0 if key=='harp' else 12) if match else 60
  x,s=sf.read(dest,always_2d=True);x=x.mean(axis=1)
  if s!=SR:x=resample_poly(x,SR,s)
  active=np.flatnonzero(np.abs(x)>max(.0004,np.max(abs(x))*.015))
  if len(active):x=x[max(0,active[0]-int(SR*.004)):]
  x=x.astype(np.float64);x/=max(.05,np.max(abs(x)));sources.setdefault(key,[]).append((pitch,x))
 rng=np.random.default_rng(4016)
 @functools.lru_cache(maxsize=512)
 def sample(kind,pitch):
  base,x=min(sources[kind],key=lambda p:abs(p[0]-pitch));ratio=2**((pitch-base)/12)
  frac=Fraction(1/ratio).limit_denominator(5000)
  return resample_poly(x,frac.numerator,frac.denominator)

 def render(name,bars,chords,bpm):
  beat=60/bpm;duration=len(bars)*4*beat+3;mix=np.zeros((int(duration*SR),2));events=[]
  def add(kind,note,start,length,gain,pan=0):
   if note=='R':return
   pitch=midi(note) if isinstance(note,str) else note
   start=max(0,start+rng.uniform(-.007,.007));x=sample(kind,pitch).copy()
   sustained=kind in ('flute','strings');release=.12 if kind=='flute' else .34 if kind=='strings' else .55
   want=min(len(x),int((length+release)*SR));x=x[:want]
   fade=int(min(.012 if kind=='flute' else .065 if kind=='strings' else .003,length*.15)*SR)
   if fade>1:x[:fade]*=np.linspace(0,1,fade)
   end=min(len(x),int(length*SR))
   if end<len(x):x[end:]*=np.linspace(1,0,len(x)-end)**1.3
   if kind=='strings':x*=.85+.15*np.sin(np.linspace(0,np.pi,len(x)))
   x*=gain*rng.uniform(.94,1.04)
   gains=np.array([np.cos((pan+1)*np.pi/4),np.sin((pan+1)*np.pi/4)])
   offset=int(start*SR);count=min(len(x),len(mix)-offset)
   mix[offset:offset+count]+=x[:count,None]*gains
   events.append({'instrument':kind,'midi':pitch,'seconds':round(start,4),'duration':round(length,4),'gain':gain,'pan':pan})
  voicings={'C':[48,60,64,67],'G':[43,59,62,67],'Am':[45,60,64,69],'F':[41,57,60,65],'Dm':[38,57,62,65]}
  for bar,mel in enumerate(bars):
   root,third,fifth,top=voicings[chords[bar]];origin=bar*4*beat;pos=0
   for n,d in mel:
    add('flute',n,origin+pos*beat,d*beat*.88,.26,-.13)
    if n!='R' and (pos==0 or d>=1.5):add('glock',midi(n)+12,origin+pos*beat,d*beat*.9,.045,.36)
    pos+=d
   assert abs(pos-4)<.0001,(bar,pos)
   strength=1 if bar>=4 else .76
   # Dancing, voiced arpeggios; bass on downbeats, a soft offbeat tambourine.
   pattern=[third,fifth,top,fifth,third,top,fifth,top]
   for i,n in enumerate(pattern):
    add('harp',n,origin+i*.5*beat,.45*beat,.085*strength,-.35)
    if bar>=2:add('pizz',n,origin+i*.5*beat,.32*beat,.072*strength,.28)
   for i in [0,2]:add('cello',root,origin+i*beat,.75*beat,.19,-.05)
   if bar>=4 or name.endswith('jesus-loves-me'):
    for n in [third,fifth,top]:add('strings',n,origin,3.65*beat,.055,.10)
   for i in range(8):add('shaker',60,origin+i*.5*beat,.12,.012*(1 if i%2 else .65),.55)
   for i in [1,3]:add('tambourine',60,origin+i*beat,.16,.011,-.48)
   if bar%4==3:add('marimba',72+(top%12),origin+3*beat,.60,.055,.05)
  # Final warm tonic, glistening harp and soft room decay.
  last=(len(bars)*4-1)*beat
  for i,n in enumerate([48,60,64,67,72]):add('harp',n,last+i*.045,1.8,.07,-.20+i*.1)
  irlen=int(SR*.85);room=np.zeros((irlen,2))
  for channel in range(2):
   for delay,level in [(.041,.10),(.073,.08),(.117,.06),(.173,.045),(.239,.03),(.313,.024)]:room[int(SR*(delay+channel*.007)),channel]=level
   noise=rng.normal(size=irlen);smooth=sosfilt(butter(1,4500,fs=SR,output='sos'),noise)
   room[:,channel]+=smooth*np.exp(-np.arange(irlen)/SR*7)*.00045
  for channel in range(2):mix[:,channel]+=fftconvolve(mix[:,1-channel],room[:,channel])[:len(mix)]
  mix=sosfilt(butter(2,50,fs=SR,btype='highpass',output='sos'),mix,axis=0)
  mix=np.tanh(mix*1.15);mix*=min(.89/max(.001,abs(mix).max()),.14/max(.001,np.sqrt(np.mean(mix**2))))
  fade=int(SR*.05);mix[:fade]*=np.linspace(0,1,fade)[:,None];fade=int(SR*1.3);mix[-fade:]*=np.linspace(1,0,fade)[:,None]
  assert np.isfinite(mix).all() and np.max(abs(mix))<1
  wav=cache.parent/(name+'.wav');sf.write(wav,mix,SR,subtype='PCM_24')
  out=ROOT/'BibleQuest/Noah Games/Audio/RainOrchestra/Music'/(name+'.m4a')
  subprocess.run(['afconvert',str(wav),str(out),'-f','m4af','-d','aac','-b','256000'],check=True)
  return {'file':str(out.relative_to(ROOT)),'durationSeconds':round(duration,3),'bpm':bpm,'key':'C major','peakDBFS':round(20*np.log10(abs(mix).max()),2),'rmsDBFS':round(20*np.log10(np.sqrt(np.mean(mix**2))),2),'events':events}
 original=[
 [('E5',.75),('G5',.25),('E5',.5),('D5',.5),('C5',.5),('E5',.5),('G4',1)],
 [('D5',.5),('G5',.5),('A5',.5),('G5',.5),('D5',1),('B4',.5),('G4',.5)],
 [('E5',.75),('A5',.25),('G5',.5),('E5',.5),('C5',1),('A4',1)],
 [('A4',.5),('C5',.5),('D5',.5),('E5',.5),('C5',1.5),('R',.5)],
 [('E5',.5),('G5',.5),('C6',.75),('B5',.25),('G5',.5),('E5',.5),('D5',1)],
 [('C5',.5),('A4',.5),('C5',.5),('F5',.5),('E5',1),('C5',1)],
 [('D5',.75),('F5',.25),('A5',.5),('F5',.5),('E5',.5),('D5',.5),('C5',.5),('D5',.5)],
 [('B4',.5),('D5',.5),('G5',1),('D5',1),('R',1)],
 [('A5',.5),('G5',.5),('F5',.75),('E5',.25),('D5',.5),('C5',.5),('A4',1)],
 [('G4',.5),('C5',.5),('E5',.5),('G5',.5),('C6',1.5),('B5',.5)],
 [('A5',.5),('G5',.5),('D5',.5),('B4',.5),('G4',1),('D5',1)],
 [('E5',.75),('G5',.25),('E5',.5),('D5',.5),('C5',2)]]
 # Bradbury's 1862 public-domain refrain, transposed to C; new accompaniment.
 hymn=[
 [('G4',2),('E4',1),('G4',1)], [('A4',1),('C5',3)],
 [('G4',2),('E4',1),('C4',1)], [('E4',1),('D4',3)],
 [('G4',2),('E4',1),('G4',1)], [('A4',1),('C5',2),('A4',1)],
 [('G4',1),('C4',1),('E4',1.5),('D4',.5)], [('C4',4)]]
 tracks=[render('rain-song-after-the-rain',original,['C','G','Am','F','C','F','Dm','G','F','C','G','C'],112),render('rain-song-jesus-loves-me',hymn,['C','F','C','G','C','F','G','C'],104)]
 (ROOT/'docs/rain-orchestra-music-render.json').write_text(json.dumps({'renderer':'scripts/audio/render_rain_music.py','sampleLicense':'CC0-1.0','tracks':tracks},indent=2)+'\n')
 print([(p['file'],p['durationSeconds'],p['peakDBFS'],p['rmsDBFS']) for p in tracks])

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--cache',default='/tmp/BibleQuest-RainMusic/samples');args=p.parse_args();main(args.cache)
