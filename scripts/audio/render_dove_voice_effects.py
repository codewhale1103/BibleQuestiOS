#!/usr/bin/env python3
"""Split the authorized ElevenLabs Anna master and render original dove Foley.
Convert the downloaded MP3 to WAV with afconvert first, then pass --master.
No speech service credentials or downloaded full master are stored in the repo.
"""
from pathlib import Path
import argparse,json,subprocess
import numpy as np,soundfile as sf
from scipy.signal import butter,sosfilt
clips=[
('first',"Little wings, a great big world! Hold your finger on either side of the sky to guide our dove. Move up or down to glide. Let's look for a place to rest."),
('water',"Look at the silver water. So much sky, and so much sea! Let's look a little farther."),
('homeward',"The dove found no place to rest. That's all right. Noah is waiting. Let's follow the breeze back to the ark."),
('land',"There's Noah's welcoming hand! Gently carry the dove down into his open palm."),
('welcome',"Welcome home, little dove. Noah brought the bird safely back inside. Sometimes hope means waiting a little longer."),
('wait',"Noah waited seven more days. Watch the sun and moon turn the days. Then we can open the window again."),
('second',"Seven days later, Noah sent the dove out again. Look for a little green sign that the waters are going down."),
('landscape',"Look! More land is appearing. Follow the warm breeze toward the olive grove."),
('grove',"A fresh olive leaf! Pick it up gently, and carry it to the dove's beak."),
('leaf',"A little leaf, a great big hope! Carry our green discovery home to Noah."),
('delivered',"In the evening, the dove returned with a fresh olive leaf. Now Noah knew that the waters had gone down."),
('third',"After seven more days, Noah sent the dove out again. Follow the greener coast. What a beautiful place to explore!"),
('branch',"A sunlit branch, and green leaves all around. Gently guide the dove onto this peaceful resting place."),
('finale',"This time, the dove did not return to the ark. New life was growing beyond the water. Noah kept waiting and trusting God. Little wings had brought a great big hope."),
('hint',"Hold your finger toward the side you want to fly. Let go to glide quietly. You can also tap Follow the breeze for a little help."),
('reflection',"Calm water can be like a mirror. Can you see the sky reflected in the sea?"),
('waterfall',"Water flows downhill. When it tumbles over rocks, it can make a beautiful waterfall."),
('olive',"Olive leaves are narrow and green. A fresh leaf showed Noah that the waters were going down.")]
parser=argparse.ArgumentParser();parser.add_argument('--master',default='/tmp/DoveVoyage-Anna-master.wav');args=parser.parse_args()
x,sr=sf.read(args.master);x=x.mean(axis=1) if x.ndim>1 else x
hop=int(sr*.02);a=np.sqrt(np.mean(x[:len(x)//hop*hop].reshape(-1,hop)**2,axis=1));q=a<.003
e=np.diff(np.r_[False,q,False].astype(int));gaps=[(i*hop,j*hop) for i,j in zip(np.where(e==1)[0],np.where(e==-1)[0]) if (j-i)*.02>=1.2 and i*hop>sr*.2 and j*hop<len(x)-sr*.2]
assert len(gaps)==len(clips)-1
bounds=[0]+[int((i+j)/2) for i,j in gaps]+[len(x)]
out=Path('BibleQuest/Noah Games/Audio/Dove');out.mkdir(exist_ok=True)
m={'provider':'ElevenLabs','voice':"Anna - Children's Book Narrator",'model':'Eleven Multilingual v2','generated':'2026-10-17','settings':{'speed':1,'stability':.5,'similarity':.75,'style':0,'speakerBoost':True},'licenseStatus':'Local preview only. Generated on Free plan. Regenerate under a paid commercial plan before commercial release.','clips':[]}
for (id,text),start,end in zip(clips,bounds,bounds[1:]):
 y=x[start:end].copy();active=np.flatnonzero(abs(y)>.003);assert len(active)>sr*.5
 y=y[max(0,active[0]-int(sr*.08)):min(len(y),active[-1]+int(sr*.16))]
 n=int(sr*.012);y[:n]*=np.linspace(0,1,n);y[-n:]*=np.linspace(1,0,n)
 tmp=Path('/tmp')/('dove-'+id+'.wav');sf.write(tmp,y,sr,subtype='PCM_16')
 file='dove-voice-'+id+'.m4a';subprocess.run(['afconvert',str(tmp),str(out/file),'-f','m4af','-d','aac','-b','128000'],check=True)
 m['clips'].append({'id':id,'text':text,'file':file,'durationSeconds':round(len(y)/sr,3)})
Path('docs/dove-voyage-narration.json').write_text(json.dumps(m,indent=2)+'\n')
# Original designed air, feather and leaf Foley. Not field recordings.
sr=32000;rng=np.random.default_rng(812)
def save(name,y):
 y=np.asarray(y);y*=.65/max(.001,abs(y).max());n=min(int(sr*.02),len(y)//4);y[:n]*=np.linspace(0,1,n);y[-n:]*=np.linspace(1,0,n);sf.write(out/(name+'.wav'),y,sr,subtype='PCM_16')
t=np.arange(sr*12)/sr
water=sosfilt(butter(2,900,fs=sr,output='sos'),rng.normal(size=len(t)))
water*=.6+.2*np.sin(t*1.5)+.1*np.sin(t*2.37)
air=sosfilt(butter(1,2200,fs=sr,output='sos'),rng.normal(size=len(t)))*.22
save('dove-air',water+air)
t=np.arange(int(sr*.7))/sr;noise=sosfilt(butter(2,[700,5500],fs=sr,btype='bandpass',output='sos'),rng.normal(size=len(t)))
save('dove-wing',noise*np.sin(np.pi*t/.7)**3)
t=np.arange(int(sr*.5))/sr;save('dove-leaf',sosfilt(butter(2,[1700,7000],fs=sr,btype='bandpass',output='sos'),rng.normal(size=len(t)))*np.sin(np.pi*t/.5)**2*np.exp(-t*4))
t=np.arange(sr*3)/sr;y=np.zeros_like(t)
for i,f in enumerate([523.25,659.25,783.99]):
 age=np.maximum(0,t-i*.18);y+=(t>=i*.18)*np.sin(2*np.pi*f*age)*np.exp(-age*2.6)*np.minimum(1,age/.012)*.3
save('dove-glimmer',y)
print('Saved',len(clips),'Anna clips and 4 designed cues')
