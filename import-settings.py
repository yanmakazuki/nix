import subprocess, plistlib, json, pathlib, datetime, urllib.parse, math
root=pathlib.Path(__file__).resolve().parent
B='bool'; I='int'; F='float'; S='str'
def specs(b='',i='',f='',s=''):
 return {**dict.fromkeys(b.split(),B),**dict.fromkeys(i.split(),I),**dict.fromkeys(f.split(),F),**dict.fromkeys(s.split(),S)}
mapping={
 'dock':('com.apple.dock',specs(b='autohide expose-group-apps magnification minimize-to-application show-process-indicators show-recents showDesktopGestureEnabled showAppExposeGestureEnabled showMissionControlGestureEnabled showLaunchpadGestureEnabled launchanim mru-spaces static-only',i='tilesize largesize wvous-tl-corner wvous-tr-corner wvous-bl-corner wvous-br-corner',f='autohide-delay autohide-time-modifier expose-animation-duration',s='orientation mineffect')),
 'finder':('com.apple.finder',specs(b='AppleShowAllFiles AppleShowAllExtensions ShowPathbar ShowStatusBar ShowExternalHardDrivesOnDesktop ShowHardDrivesOnDesktop ShowMountedServersOnDesktop ShowRemovableMediaOnDesktop FXEnableExtensionChangeWarning FXRemoveOldTrashItems CreateDesktop QuitMenuItem _FXSortFoldersFirst _FXSortFoldersFirstOnDesktop _FXShowPosixPathInTitle',s='FXPreferredViewStyle FXDefaultSearchScope NewWindowTarget NewWindowTargetPath')),
 'NSGlobalDomain':('NSGlobalDomain',specs(b='AppleEnableSwipeNavigateWithScrolls AppleInterfaceStyleSwitchesAutomatically ApplePressAndHoldEnabled AppleShowAllExtensions NSAutomaticCapitalizationEnabled NSAutomaticPeriodSubstitutionEnabled NSAutomaticDashSubstitutionEnabled NSAutomaticQuoteSubstitutionEnabled NSAutomaticSpellingCorrectionEnabled NSAutomaticInlinePredictionEnabled NSAutomaticWindowAnimationsEnabled AppleScrollerPagingBehavior AppleSpacesSwitchOnActivate NSDocumentSaveNewDocumentsToCloud _HIHideMenuBar com.apple.springing.enabled com.apple.trackpad.forceClick',i='KeyRepeat InitialKeyRepeat AppleKeyboardUIMode AppleFontSmoothing',f='com.apple.springing.delay com.apple.trackpad.scaling',s='AppleInterfaceStyle AppleIconAppearanceTheme AppleWindowTabbingMode AppleShowScrollBars')),
 'trackpad':('com.apple.AppleMultitouchTrackpad',specs(b='Clicking Dragging DragLock ActuateDetents ForceSuppressed TrackpadRightClick TrackpadThreeFingerDrag TrackpadMomentumScroll TrackpadPinch TrackpadRotate TrackpadTwoFingerDoubleTapGesture',i='FirstClickThreshold SecondClickThreshold TrackpadCornerSecondaryClick TrackpadFourFingerHorizSwipeGesture TrackpadFourFingerVertSwipeGesture TrackpadFourFingerPinchGesture TrackpadThreeFingerHorizSwipeGesture TrackpadThreeFingerVertSwipeGesture TrackpadThreeFingerTapGesture')),
 'WindowManager':('com.apple.WindowManager',specs(b='GloballyEnabled EnableStandardClickToShowDesktop AutoHide AppWindowGroupingBehavior StandardHideDesktopIcons HideDesktop EnableTilingByEdgeDrag EnableTopTilingByEdgeDrag EnableTilingOptionAccelerator EnableTiledWindowMargins StandardHideWidgets StageManagerHideWidgets')),
}
custom={
 'NSGlobalDomain':['AppleLanguages','AppleLocale','AppleMenuBarVisibleInFullscreen','AppleMiniaturizeOnDoubleClick','NSUserDictionaryReplacementItems'],
 'com.apple.menuextra.clock':['ShowAMPM','ShowDate','ShowDayOfWeek','ShowSeconds'],
 'com.apple.controlcenter':['AutoHideMenuBarOption','NSStatusItem VisibleCC Battery','NSStatusItem VisibleCC Display','NSStatusItem VisibleCC Sound','NSStatusItem VisibleCC WiFi'],
 'com.apple.HIToolbox':['AppleFnUsageType','AppleCapsLockPressAndHoldToggleOff'],
}
cache={};missing=[];records=[]
def read(domain):
 if domain not in cache:
  p=subprocess.run(['/usr/bin/defaults','export',domain,'-'],capture_output=True)
  cache[domain]=plistlib.loads(p.stdout) if p.returncode==0 else {}
 return cache[domain]
def normalize(v,t):
 if t==B:
  if v not in (0,1,False,True):raise ValueError('invalid boolean')
  return bool(v)
 if t==I:
  if not isinstance(v,(int,float)) or not math.isfinite(v) or int(v)!=v:raise ValueError('invalid integer')
  return int(v)
 if t==F:
  if not isinstance(v,(int,float)) or not math.isfinite(v):raise ValueError('invalid number')
  return float(v)
 if t==S and isinstance(v,str):return v
 raise ValueError('invalid type')
def nix(v):
 if isinstance(v,bool):return 'true' if v else 'false'
 if isinstance(v,str):return json.dumps(v,ensure_ascii=False).replace('${','\\${')
 if isinstance(v,(int,float)):return repr(v)
 if isinstance(v,list):return '[ '+ ' '.join(nix(x) for x in v)+' ]'
 if isinstance(v,dict):return '{ '+ ' '.join(nix(k)+' = '+nix(x)+';' for k,x in v.items())+' }'
 raise ValueError('unsupported plist value')
values={}
for group,(domain,schema) in mapping.items():
 out={};d=read(domain)
 for key,t in schema.items():
  if key not in d:missing.append(domain+':'+key);continue
  raw=d[key];val=normalize(raw,t)
  if key=='NewWindowTarget':val={'PfCm':'Computer','PfVo':'OS volume','PfHm':'Home','PfDe':'Desktop','PfDo':'Documents','PfAF':'Recents','PfID':'iCloud Drive','PfLo':'Other'}[val]
  if key=='NewWindowTargetPath' and d.get('NewWindowTarget')!='PfLo':continue
  out[key]=val;records.append({'domain':domain,'key':key,'source':raw,'nix':val,'option':group+'.'+key})
 values[group]=out
# DockのブックマークやGUIDを除き、保存されたアプリ順をパスに変換。
d=read('com.apple.dock');apps=[]
for tile in d.get('persistent-apps',[]):
 kind=tile.get('tile-type');url=tile.get('tile-data',{}).get('file-data',{}).get('_CFURLString')
 if kind in ('spacer-tile','small-spacer-tile'):apps.append({'spacer':{'small':kind=='small-spacer-tile'}})
 elif url and urllib.parse.urlparse(url).scheme=='file':
  path=urllib.parse.unquote(urllib.parse.urlparse(url).path).rstrip('/')
  if not pathlib.Path(path).exists():raise ValueError('Dock path missing: '+path)
  apps.append({'app':path})
 else:raise ValueError('Unsupported Dock tile; refusing incomplete order')
if 'persistent-apps' in d:
 values['dock']['persistent-apps']=apps
 records.append({'domain':'com.apple.dock','key':'persistent-apps','source':[x for x in apps],'nix':apps,'option':'dock.persistent-apps'})
if d.get('persistent-others')==[]:
 values['dock']['persistent-others']=[]
 records.append({'domain':'com.apple.dock','key':'persistent-others','source':[],'nix':[],'option':'dock.persistent-others'})
values['CustomUserPreferences']={}
for domain,keys in custom.items():
 out={};d=read(domain)
 for key in keys:
  if key not in d:missing.append(domain+':'+key);continue
  nix(d[key]);out[key]=d[key];records.append({'domain':domain,'key':key,'source':d[key],'nix':d[key],'option':'CustomUserPreferences.'+domain+'.'+key})
 if out:values['CustomUserPreferences'][domain]=out
lines=['# defaultsから読み取った保存値。取り込みスクリプトで生成。','{ ... }:', '{','  system.defaults = {']
for group,out in values.items():
 if not out:continue
 lines.append('    '+group+' = {')
 for k,v in out.items():lines.append('      '+nix(k)+' = '+nix(v)+';')
 lines.append('    };')
lines+=['  };','}','']
root.joinpath('captured-defaults.nix').write_text('\n'.join(lines))
root.joinpath('capture-report.json').write_text(json.dumps({'capturedAt':datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=9))).isoformat(),'managedCount':len(records),'settings':records,'notStored':missing,'notes':['保存されたユーザー設定のみ。OS標準値、MDM、ByHost設定は網羅しない。','Bluetoothトラックパッド、入力ソース一覧、ショートカット、壁紙、ディスプレイ、電源、ネットワーク、権限は取り込んでいない。','CustomUserPreferencesの項目はmacOS固有キーをそのまま保存。適用の実動作は未検証。']},ensure_ascii=False,indent=2)+'\n')
print('Captured',len(records),'settings;',len(missing),'candidate keys absent.')
