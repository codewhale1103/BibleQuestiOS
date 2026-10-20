#!/usr/bin/env python3
"""Original Wings of Hope score. CC0 VSCO 2 CE flute, harp and strings.
Reuses the pinned sample inventory documented for Rain Orchestra; no shared output.
"""
from pathlib import Path
from fractions import Fraction
import functools,json,re,subprocess,urllib.parse,urllib.request
import numpy as np,soundfile as sf
from scipy.signal import resample_poly,fftconvolve,butter,sosfilt
from render_rain_music import midi,SR,ROOT

def main():
 cache=Path('/tmp/BibleQuest-RainMusic/samples');inventory=json.loads((ROOT/'docs/rain-orchestra-music-samples.json').read_text());sources={}
 for file in inventory['samples']:
  kind='flute' if 'Flute/' in file else 'harp' if '/Harp/' in file else 'strings' if '/susVib/' in file else 'cello' if '/pizzT/' in file else 'glock' if '/Glock/' in file else None
  if not kind:continue
  p=cache/file
  if not p.exists():
   p.parent.mkdir(parents=True,exist_ok=True);urllib.request.urlretrieve('https://raw.githubusercontent.com/sgossner/VSCO-2-CE/'+inventory['commit']+'/'+urllib.parse.quote(file),p)
  m=re.search(r'_([A-G]#?\d)_',p.name) or re.search(r'_([A-G]#?\d)\.',p.name);pitch=midi(m[1])+(0 if kind=='harp' else 12)
  x,s=sf.read(p,always_2d=True);x=x.mean(axis=1)
  if s!=SR:x=resample_poly(x,SR,s)
  active=np.flatnonzero(abs(x)>max(.0004,abs(x).max()*.015));x=x[max(0,active[0]-int(SR*.004)):]
  x/=max(.05,abs(x).max());sources.setdefault(kind,[]).append((pitch,x))
 @functools.lru_cache(maxsize=256)
 def sample(kind,pitch):
  base,x=min(sources[kind],key=lambda v:abs(v[0]-pitch));r=Fraction(2**((base-pitch)/12)).limit_denominator(5000);return resample_poly(x,r.numerator,r.denominator)
 rng=np.random.default_rng(8812);beat=60/88;bars=[
 [('G4',1),('C5',1.5),('E5',.5),('D5',1)],
 [('E5',1.5),('G5',.5),('E5',1),('D5',1)],
 [('C5',1),('A4',1),('C5',1),('E5',1)],
 [('D5',2),('B4',1),('G4',1)],
 [('A4',1),('C5',1),('F5',1.5),('E5',.5)],
 [('D5',1.5),('E5',.5),('G5',1),('E5',1)],
 [('F5',1),('E5',.5),('D5',.5),('C5',1),('A4',1)],
 [('B4',1),('D5',1),('G4',2)],
 [('E5',1),('G5',1),('C6',1.5),('B5',.5)],
 [('A5',1.5),('G5',.5),('E5',1),('C5',1)],
 [('F5',1),('E5',1),('D5',1),('B4',1)],
 [('C5',3),('R',1)]]
 chords=[[48,60,64,67],[43,59,62,67],[45,57,60,64],[43,59,62,67],[41,57,60,65],[48,60,64,67],[38,57,62,65],[43,59,62,67],[48,60,64,67],[45,57,60,64],[43,59,62,67],[48,60,64,67]]
 duration=len(bars)*4*beat+2.5;mix=np.zeros((int(duration*SR),2));events=[]
 def add(kind,note,when,length,gain,pan=0):
  if note=='R':return
  pitch=midi(note) if isinstance(note,str) else note;x=sample(kind,pitch).copy();release=.3 if kind in ['flute','strings'] else .7;x=x[:int((length+release)*SR)]
  n=min(len(x)//2,int((.045 if kind=='strings' else .014 if kind=='flute' else .003)*SR));x[:n]*=np.linspace(0,1,n)
  end=int(length*SR)
  if end<len(x):x[end:]*=np.linspace(1,0,len(x)-end)**1.4
  start=int(max(0,when+rng.uniform(-.006,.006))*SR);count=min(len(x),len(mix)-start);x=x[:count]*gain*rng.uniform(.96,1.03)
  mix[start:start+count]+=x[:,None]*np.array([np.cos((pan+1)*np.pi/4),np.sin((pan+1)*np.pi/4)])
  events.append({'instrument':kind,'midi':pitch,'seconds':round(when,3),'duration':round(length,3)})
 for i,(mel,c) in enumerate(zip(bars,chords)):
  origin=i*4*beat;pos=0
  for note,length in mel:
   add('flute',note,origin+pos*beat,length*beat*.92,.22,-.15)
   if i>=8 and pos==0 and note!='R':add('glock',midi(note)+12,origin+pos*beat,1.3,.035,.35)
   pos+=length
  assert pos==4
  root,a,b,c=c
  for j,n in enumerate([a,b,c,b,a,c,b,c]):add('harp',n,origin+j*.5*beat,.47*beat,.08,-.35)
  for n in [a,b,c]:add('strings',n,origin,3.75*beat,.055 if i<8 else .07,.2)
  add('cello',root,origin,1.7*beat,.15,0);add('cello',root+12,origin+2*beat,1.5*beat,.08,0)
 # A short room response keeps the acoustic samples warm without blurring the melody.
 for ch in range(2):
  ir=np.zeros(int(SR*.8))
  for delay,gain in [(.045,.11),(.089,.08),(.163,.05),(.267,.03)]:ir[int(SR*(delay+ch*.007))]=gain
  mix[:,ch]+=fftconvolve(mix[:,1-ch],ir)[:len(mix)]
 mix=sosfilt(butter(2,55,fs=SR,btype='highpass',output='sos'),mix,axis=0);mix=np.tanh(mix)
 mix*=min(.87/abs(mix).max(),.13/np.sqrt(np.mean(mix**2)))
 n=int(SR*.07);mix[:n]*=np.linspace(0,1,n)[:,None];n=int(SR*1.4);mix[-n:]*=np.linspace(1,0,n)[:,None]
 assert np.isfinite(mix).all() and abs(mix).max()<1
 wav=Path('/tmp/dove-song-wings-of-hope.wav');sf.write(wav,mix,SR,subtype='PCM_24')
 out=ROOT/'BibleQuest/Noah Games/Audio/Dove/dove-song-wings-of-hope.m4a';subprocess.run(['afconvert',str(wav),str(out),'-f','m4af','-d','aac','-b','256000'],check=True)
 (ROOT/'docs/dove-voyage-music.json').write_text(json.dumps({'title':'Wings of Hope','composition':'Original for BibleQuest','sampleLicense':'CC0-1.0','sampleInventory':'docs/rain-orchestra-music-samples.json','commit':inventory['commit'],'renderer':'scripts/audio/render_dove_music.py','file':str(out.relative_to(ROOT)),'seconds':duration,'bpm':88,'peakDBFS':float(20*np.log10(abs(mix).max())),'rmsDBFS':float(20*np.log10(np.sqrt(np.mean(mix**2)))),'events':events},indent=2)+'\n')
 print('Rendered Wings of Hope:',round(duration,2),'seconds')
if __name__=='__main__':main()
